// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use serde_json::Value;

use std::{
    error::Error,
    fs::File,
    io::{self, Read, Write},
    net::{TcpListener, TcpStream},
    thread,
    time::Duration,
};

#[derive(Debug, Serialize, Deserialize)]
struct ClientRequest {
    type_: String,
    data: serde_json::Value,
}

fn read_json_file(path: &str) -> Result<Value, Box<dyn Error>> {
    let mut file = File::open(path)?;
    let mut contents = String::new();

    file.read_to_string(&mut contents)?;

    let json: Value = serde_json::from_str(&contents)?;

    Ok(json)
}

fn handle_client(mut stream: TcpStream, timeout: String) {
    // Remove inactive BizHawk clients
    stream
        .set_read_timeout(Some(Duration::from_millis(
            timeout.parse::<u64>().expect("Invalid timeout value"),
        )))
        .expect("set_read_timeout failed");

    // Parse incoming data
    let mut buffer = String::new();
    while let Ok(n) = stream.read_to_string(&mut buffer) {
        if n == 0 {
            break; // Connection closed
        }

        match serde_json::from_str::<ClientRequest>(&buffer) {
            Ok(request) => {
                match request.type_.as_str() {
                    "data_type" => {
                        println!("Received data_type request: {:?}", request.data);

                        let response = ClientRequest {
                            type_: "response".to_string(),
                            data: serde_json::json!({"message": "Response data"}),
                        };

                        // Serialize the response as JSON and send it back
                        let response_json = serde_json::to_string(&response).unwrap();
                        stream.write(response_json.as_bytes()).ok();
                    }
                    "comm_check" => {
                        println!("Client tested its connection");
                    }
                    _ => {
                        println!("Received unknown request type: {}", request.type_);
                    }
                }
            }
            Err(e) => {
                eprintln!("Error parsing JSON: {}", e);
            }
        }

        buffer.clear();
    }

    println!("Client removed: {}", stream.peer_addr().unwrap());
}

fn client_send(
    mut stream: &TcpStream,
    msg_type: &str,
    msg_data: &serde_json::Value,
) -> io::Result<()> {
    let response = ClientRequest {
        type_: msg_type.to_string(),
        data: msg_data.clone(),
    };

    let response_string = serde_json::to_string(&response)?;
    let message = format!("{} {}", response_string.len(), response_string); // Socket messages to BizHawk must be in the format of 'length + ' ' + message'

    stream.write_all(message.as_bytes())?;

    Ok(())
}

fn main() {
    let mut config: Value = serde_json::json!({});

    match read_json_file("../../config.json") {
        Ok(data) => {
            config = data;
        }
        Err(err) => {
            eprintln!("Error reading/parsing JSON data: {}", err);
        }
    }

    // Create separate thread to listen out for BizHawk clients
    let server_thread = thread::spawn(move || {
        let listener = TcpListener::bind("127.0.0.1:51055").expect("Failed to bind to port");

        println!("Server listening on 127.0.0.1:51055");

        for stream in listener.incoming() {
            match stream {
                Ok(stream) => {
                    let config = config.clone(); // Prevents 'borrow of moved value: config'

                    // Send config to connecting clients
                    let _ = client_send(
                        &stream,
                        "apply_config",
                        &serde_json::json!({"config": config}),
                    );

                    thread::spawn(move || {
                        handle_client(
                            stream,
                            config["inactive_client_timeout"]
                                .as_str()
                                .unwrap_or_default()
                                .to_string(),
                        );
                    });
                }
                Err(e) => {
                    eprintln!("Error accepting connection: {}", e);
                }
            }
        }
    });

    // Run Tauri app window
    tauri::Builder::default()
        .run(tauri::generate_context!())
        .expect("error while running tauri application");

    server_thread.join().expect("TCP server thread panicked");
}

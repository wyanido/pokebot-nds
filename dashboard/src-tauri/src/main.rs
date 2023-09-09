// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use serde_json::Value;
use tauri::{Manager, PhysicalSize};

use std::{
    error::Error,
    fs::File,
    io::{self, Read, Write},
    net::{TcpListener, TcpStream},
    sync::Mutex,
    thread,
    time::Duration,
};

lazy_static::lazy_static! {
    static ref CONFIG: Mutex<Value> = Mutex::new(serde_json::json!({}));
}

#[derive(Debug, Serialize, Deserialize)]
struct ClientMessage {
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

fn read_message(stream: &mut TcpStream) -> Result<Value, std::io::Error> {
    let mut buffer = Vec::new();
    let null_terminator: u8 = 0;

    loop {
        let mut byte = [0; 1];
        let result = stream.read_exact(&mut byte);

        match result {
            Ok(()) => {
                if byte[0] == null_terminator {
                    break;
                }
                buffer.push(byte[0]);
            }
            Err(e) => return Err(e),
        }
    }

    let message_string = String::from_utf8(buffer).expect("Invalid UTF-8 data");
    let (_, json_string) = message_string.split_at(message_string.find(' ').unwrap_or(0));
    let message: serde_json::Value =
        serde_json::from_str(json_string).expect("JSON was not well-formatted");

    Ok(message)
}

fn set_client_timeout(stream: &mut TcpStream, timeout: String) {
    stream
        .set_read_timeout(Some(Duration::from_millis(
            timeout.parse::<u64>().expect("Invalid timeout value"),
        )))
        .expect("set_read_timeout failed");
}
fn handle_client(mut stream: TcpStream, timeout: String) {
    set_client_timeout(&mut stream, timeout);

    // Continously listen for client messages until disconnect
    loop {
        match read_message(&mut stream) {
            Ok(message) => {
                println!("Received message: {}", message.to_string());

                match message["type_"].as_str() {
                    Some("comm_check") => {
                        println!("Client tested its connection!");
                    }
                    Some("init") => {
                        println!("Received 'init' message from client");
                    }
                    Some("party") => {
                        println!("Received party data!");
                    }
                    Some("game") => {
                        println!("Game state updated");
                    }
                    Some("seen") => {
                        println!("Found a Pokémon!");
                    }
                    Some("seen_target") => {
                        println!("Found a target Pokémon!");
                    }
                    _ => {
                        println!("Received unknown message type: {}", message["type_"]);
                    }
                }
            }
            Err(e) => {
                eprintln!("{}", e);
                break; // Exit loop on error
            }
        }
    }
}

fn client_send(
    mut stream: &TcpStream,
    msg_type: &str,
    msg_data: &serde_json::Value,
) -> io::Result<()> {
    let response = ClientMessage {
        type_: msg_type.to_string(),
        data: msg_data.clone(),
    };

    let response_string = serde_json::to_string(&response)?;
    let message = format!("{} {}", response_string.len(), response_string); // Socket messages to BizHawk must be in the format of 'length + ' ' + message'

    stream.write_all(message.as_bytes())?;

    Ok(())
}

fn main() {
    match read_json_file("../../config.json") {
        Ok(data) => {
            *CONFIG.lock().unwrap() = data;
        }
        Err(err) => {
            eprintln!("Error reading/parsing JSON data: {}", err);
        }
    }

    #[tauri::command]
    fn return_config() -> Result<String, ()> {
        let config = CONFIG.lock().unwrap();
        Ok(format!("{}", *config))
    }

    // Create separate thread to listen out for BizHawk clients
    let server_thread = thread::spawn(move || {
        let listener = TcpListener::bind("127.0.0.1:51055").expect("Failed to bind to port");

        println!("Server listening on 127.0.0.1:51055");

        for stream in listener.incoming() {
            match stream {
                Ok(stream) => {
                    let config = CONFIG.lock().unwrap();
                    let timeout = config["inactive_client_timeout"]
                        .as_str()
                        .unwrap_or_default()
                        .to_string();

                    // Send config to connecting clients
                    let _ = client_send(
                        &stream,
                        "apply_config",
                        &serde_json::json!({"config": *config}),
                    );

                    thread::spawn(move || {
                        handle_client(stream, timeout);
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
        .setup(|app| {
            let main_window = app.get_window("main").unwrap();
            main_window
                .set_min_size(Some(PhysicalSize::new(768, 432)))
                .unwrap();

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![return_config])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");

    server_thread.join().expect("TCP server thread panicked");
}

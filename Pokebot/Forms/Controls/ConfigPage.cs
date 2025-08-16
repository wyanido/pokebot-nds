using NLua;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;
using Wyanido.Pokebot.Forms;
using Wyanido.Pokebot.Forms.Controls;
using Wyanido.Pokebot.Lua;
using Wyanido.Pokebot.Utils;
using YamlDotNet.Serialization;

namespace Wyanido.Pokebot;

public partial class ConfigPage : UserControl, IContainerControl
{
    private static readonly ISerializer yamlSerialiser = new SerializerBuilder().Build();
    private static readonly IDeserializer yamlDeserialiser = new DeserializerBuilder().Build();

    private readonly Control parentContainer;
    private readonly AnchorStyles anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;

    public ConfigPage() : base()
    {
        InitializeComponent();
        parentContainer = this.flowLayoutPanel;
    }

    /// <summary>
    /// Converts a snake_case property key into a Camel Case name with spaces.
    /// </summary>
    private static string PropertyKeyToName(string key)
    {
        var words = key.Split('_');
        var name = string.Join(" ", words);
        return char.ToUpper(name[0]) + name.Substring(1);
    }

    /// <summary>
    /// Adds a checkbox to the config form.
    /// </summary>
    private void AppendCheckbox(string propertyKey, bool defaultValue)
    {
        var checkBox = new CheckBox
        {
            Text = PropertyKeyToName(propertyKey) + "?",
            Checked = defaultValue,
            Tag = propertyKey,
            AutoSize = true // Fix label being cropped
        };

        parentContainer.Controls.Add(checkBox);
    }

    /// <summary>
    /// Adds a NumericUpDown to the config form.
    /// </summary>
    private void AppendNumberInput(string propertyKey, Int64 defaultValue)
    {
        var groupBox = new GroupBox
        {
            Text = PropertyKeyToName(propertyKey),
            Height = 50,
            Anchor = anchor
        };

        var numberInput = new NumericUpDown
        {
            Value = defaultValue,
            Tag = propertyKey,
        };

        groupBox.Controls.Add(numberInput);
        parentContainer.Controls.Add(groupBox);
    }

    /// <summary>
    /// Adds a YamlTextBox to the config form.
    /// </summary>
    private void AppendYamlTextBox(string propertyKey, LuaTable defaultValue)
    {
        var groupBox = new GroupBox()
        {
            Text = PropertyKeyToName(propertyKey),
            Height = 150,
            Anchor = anchor
        };

        var table = LuaHelpers.ParseTable(defaultValue);
        var tableYaml = yamlSerialiser.Serialize(table);

        var textBox = new YamlTextBox()
        {
            Tag = propertyKey,
            Text = tableYaml,
            Dock = DockStyle.Fill
        };

        groupBox.Controls.Add(textBox);
        parentContainer.Controls.Add(groupBox);
    }

    private void AppendTextBox(string propertyKey, string defaultValue)
    {
        var groupBox = new GroupBox()
        {
            Text = PropertyKeyToName(propertyKey),
            Anchor = anchor,
            Height = 50
        };

        var textBox = new TextBox()
        {
            Tag = propertyKey,
            Text = defaultValue,
            Dock = DockStyle.Fill,
        };

        groupBox.Controls.Add(textBox);
        parentContainer.Controls.Add(groupBox);
    }

    /// <summary>
    /// Updates the control to display a list of config properties.
    /// </summary>
    public void SetLayoutFromProperties(ConfigFormProperty[] properties)
    {
        SuspendLayout();

        parentContainer.Controls.Clear();

        // Order alphabetically to make it easier to find things
        var sortedProperties = properties.OrderBy(property => property.Key);

        foreach (var property in sortedProperties)
        {
            var value = property.DefaultValue;

            // Use the most suitable form input type for the property type
            if (value is bool isChecked)
                AppendCheckbox(property.Key, isChecked);
            else if (value is Int64 number)
                AppendNumberInput(property.Key, number);
            else if (value is LuaTable table)
                AppendYamlTextBox(property.Key, table);
            else if (value is string stringValue)
                AppendTextBox(property.Key, stringValue);
            else
                LuaLibraries.PrintDebug($"Couldn't add unknown property type '{property.PropertyType}' ({property.Key} = {property.DefaultValue}) to the config form");
        }

        ResumeLayout();
    }

    private void SetFromScriptConfigDeep(Control control, ref ScriptConfig scriptConfig)
    {
        foreach (Control subControl in control.Controls)
        {
            // Control is likely a GroupBox, not a property, so iterate over child controls
            if (subControl.Tag is not string key)
            {
                SetFromScriptConfigDeep(subControl, ref scriptConfig);
                continue;
            }

            scriptConfig.Properties.TryGetValue(key, out object value);

            // The ScriptConfig lacks this property, but don't add it 
            // here because that's managed by CopyToScriptConfig.
            if (value is null)
                continue;

            // Boolean
            if (subControl is CheckBox checkbox && value is bool isChecked)
            {
                checkbox.Checked = isChecked;
                continue;
            }

            // Any numeric value
            if (subControl is NumericUpDown numericUpDown)
            {
                if (value is Int64 number)
                    numericUpDown.Value = number;
                else if (value is Decimal number2)
                    numericUpDown.Value = number2;

                continue;
            }

            // Serialise Dictionary/List into yaml for easy user editing
            if (subControl is YamlTextBox yamlTextBox)
            {
                if (value is Dictionary<object, object> dictValue)
                {
                    var stringValue = yamlSerialiser.Serialize(dictValue);
                    yamlTextBox.Text = stringValue;
                }
                else if (value is List<object> list)
                {
                    var stringValue = yamlSerialiser.Serialize(list);
                    yamlTextBox.Text = stringValue;
                }
            }

            // String
            if (subControl is TextBox textBox && value is string textValue)
                textBox.Text = textValue;
        }
    }

    /// <summary>
    /// Iterates through the config form's properties and updates the property's
    /// value if the same key exists inside the ScriptConfig.
    /// </summary>
    /// <param name="scriptConfig"></param>
    public void SetFromScriptConfig(ref ScriptConfig scriptConfig)
    {
        SetFromScriptConfigDeep(parentContainer, ref scriptConfig);
    }

    /// <summary>
    /// Safely sets the ScriptConfig's key to the given value. If the key doesn't exist,
    /// it will be added, and nothing will happen if the value is null.
    /// </summary>
    private void SafeSetKeyValue(ScriptConfig scriptConfig, string key, object? value = null)
    {
        if (value is null)
            return;

        if (scriptConfig.Properties.ContainsKey(key))
            scriptConfig.Properties[key] = value;
        else
            scriptConfig.Properties.Add(key, value);
    }

    private void CopyToScriptConfigDeep(Control control, ref ScriptConfig scriptConfig)
    {
        foreach (Control subControl in control.Controls)
        {
            // Control is likely a GroupBox, not a property, so iterate over child controls
            if (subControl.Tag is not string key)
            {
                CopyToScriptConfigDeep(subControl, ref scriptConfig);
                continue;
            }

            // Boolean
            if (subControl is CheckBox checkbox)
            {
                SafeSetKeyValue(scriptConfig, key, checkbox.Checked);
                continue;
            }

            // Number (always decimal, but YAML serialiser will use int if the value is a whole number)
            if (subControl is NumericUpDown numericUpDown)
            {
                SafeSetKeyValue(scriptConfig, key, numericUpDown.Value);
                continue;
            }

            // Deserialise YAML into List or Dictionary
            if (subControl is YamlTextBox yamlTextBox)
            {
                var value = yamlDeserialiser.Deserialize(yamlTextBox.Text);
                SafeSetKeyValue(scriptConfig, key, value);
                continue;
            }

            // String
            if (subControl is TextBox textBox)
            {
                SafeSetKeyValue(scriptConfig, key, textBox.Text);
            }
        }
    }

    /// <summary>
    /// Recursively copies the value of all script property form entries into the ScriptConfig.
    /// </summary>
    public void CopyToScriptConfig(ref ScriptConfig scriptConfig)
    {
        CopyToScriptConfigDeep(parentContainer, ref scriptConfig);
    }
}

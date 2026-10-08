# 🚀 Flutter Deployment Pipeline

This repository contains a centralized deployment pipeline script for Flutter projects. It helps automate and streamline the build, test, and deployment process for Android and iOS apps. The script is designed to work directly from your project folder and ensures compatibility with multiple projects.

The script relies on **Fastlane** to handle the deployment process for both Android and iOS platforms.

---

## 🛠️ Current Compatibility

This script is currently only available for **macOS**. Contributions to make it compatible with other operating systems (e.g., Linux, Windows) are very welcome! 🙌

---

## 📋 How to Use

1. **Navigate to your Flutter project directory**:
   Ensure you're in the root directory of your Flutter project (the folder containing `pubspec.yaml`).

   ```bash
   cd /path/to/your/flutter_project
   ```

2. **Run the script**:
   Use the following command to deploy your app:

   - For Android:
     ```bash
     bash /shared/scripts/deploy_pipeline.sh android
     ```

   - For iOS:
     ```bash
     bash /shared/scripts/deploy_pipeline.sh ios
     ```

   - For both platforms:
     ```bash
     bash /shared/scripts/deploy_pipeline.sh
     ```

3. **Script validation**:
   If you're not in a valid Flutter project directory, the script will alert you:
   ```
   ❌ Error: 'pubspec.yaml' not found in the current directory.
   ```

4. **Enable verbose mode**:
   To display detailed logs during execution, use the `--verbose` flag:
   ```bash
   bash /shared/scripts/deploy_pipeline.sh --verbose android
   ```

5. **Skip code analysis**:
   If you want to skip `flutter analyze`, use the `--skip-analyze` flag:
   ```bash
   bash /shared/scripts/deploy_pipeline.sh --skip-analyze android
   ```

6. **Skip version increment**:
   To skip incrementing the version, use the `--skip-version` flag:
   ```bash
   bash /shared/scripts/deploy_pipeline.sh --skip-version android
   ```

7. **Show help**:
   To display the available options and usage instructions, use the `-h` or `--help` flag:
   ```bash
   bash /shared/scripts/deploy_pipeline.sh --help
   ```

---

## 🔍 Help

Run the script with the `--help` flag to display the following usage instructions:

```
Usage: deploy_pipeline.sh [options] [target]

Options:
  --verbose           Show detailed logs for each command
  --skip-analyze      Skip the Flutter analyze step
  --skip-version      Skip incrementing the version
  --beta              Deploy to closed testing (TestFlight for iOS, alpha track for Android)
  -h, --help          Show this help message

Targets:
  android             Deploy only for Android
  ios                 Deploy only for iOS
  all (default)       Deploy for both Android and iOS

Examples:
  deploy_pipeline.sh android
  deploy_pipeline.sh --skip-analyze ios
  deploy_pipeline.sh --verbose --skip-version
```

---

## ✨ Recommended: Set an Alias

To simplify usage, you can set an alias for the script. This allows you to use the command `deploy_flutter` from any Flutter project directory.

### 🔧 Setting the Alias

1. Open your shell configuration file:
   - For Bash:
     ```bash
     nano ~/.bashrc
     ```
   - For Zsh:
     ```bash
     nano ~/.zshrc
     ```

2. Add the alias:
   ```bash
   alias deploy_flutter="bash /shared/scripts/deploy_pipeline.sh"
   ```

3. Save the file and reload the shell configuration:
   ```bash
   source ~/.bashrc   # For Bash
   source ~/.zshrc    # For Zsh
   ```

4. Use the alias:
   - Deploy Android:
     ```bash
     deploy_flutter android
     ```
   - Deploy iOS:
     ```bash
     deploy_flutter ios
     ```
   - Deploy both:
     ```bash
     deploy_flutter
     ```

---

## ⚡ Features

- **Platform-Specific Deployment**: Choose to deploy only for Android or iOS, or both.
- **Automatic Environment Detection**: The script verifies if you're in a valid Flutter project.
- **Step Logs**: Each step writes its output to its own file in a temporary folder (printed at start). When a step fails, the last 40 lines of its log are shown in the terminal.
- **Verbose Mode**: Use `--verbose` for detailed command logs.
- **Skip Code Analysis**: Use `--skip-analyze` to bypass `flutter analyze`.
- **Skip Version Increment**: Use `--skip-version` to avoid incrementing the version.
- **Reliable Exit Code**: When deploying both platforms in parallel, the script waits for each one and exits with an error if either fails.
- **Time Tracking**: Displays the total time taken for the pipeline to complete.
- **Fastlane Integration**: Utilizes Fastlane for streamlined Android and iOS deployment.

---

## 🤝 Contributing

Contributions are always welcome! 🎉 If you have ideas for improvements, feel free to open an issue or submit a pull request.

---

## 📜 License

This project is open-source and available under the [GPL License](LICENSE).

---

### 🌟 We value your feedback!
If you have suggestions or encounter issues, let us know. Together, we can make this tool even better! 🚀

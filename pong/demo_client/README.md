# Server Side Pong Client (SSPC)

Welcome to Server Side Pong Client (SSPC), a minimalist and fun Pong game client built using the Zig programming language.

## Current Version: v0.0.1

This is the initial version (v0.0.1) of SSPC, featuring:
- A standalone Pong game client.
- Local multiplayer gameplay.

### Roadmap
- **v1.0**: The upcoming version will include server support, enabling true multiplayer gameplay over a network. Stay tuned!

---

## Prerequisites
To run SSPC locally, you need to install the Zig compiler (version 0.13.0). Download the Zig compiler here:

[Download Zig 0.13.0](https://ziglang.org/download/)

### Adding Zig to Your Path
After downloading the Zig compiler:
1. Extract the downloaded archive to a location of your choice.
2. Add the `zig` executable to your system's PATH:
   - **On Linux/Mac**: Add the following line to your `~/.bashrc` or `~/.zshrc` file:
     ```bash
     export PATH="/path/to/zig:$PATH"
     ```
     Replace `/path/to/zig` with the actual path where you extracted Zig.
   - **On Windows**:
     - Open the Start Menu and search for "Environment Variables."
     - Under "System Variables," find the `Path` variable and click "Edit."
     - Add the path to the folder containing `zig.exe`.
3. Restart your terminal or command prompt to apply the changes.
4. Verify the installation by running:
   ```bash
   zig version
   ```
   You should see `0.13.0` as the output.

---

## Installing SSPC Locally

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/pierrelgol/ServerSidePongClient.git
   cd ServerSidePongClient
   ```

2. **Build the Game**:
   Use the Zig build system to compile the game:
   ```bash
   zig build -Doptimize=ReleaseFast
   ```

3. **Run the Game**:
   After building, the game executable will be located in the `zig-out/bin` directory:
   ```bash
   ./zig-out/bin/sspc
   ```

4. **Play**:
   Enjoy local multiplayer Pong with your friends!

---

## Controls
- **Player 1**: Use `W` to move up and `S` to move down.
- **Player 2**: Use the `Arrow Up` and `Arrow Down` keys.

---

## Future Plans
- **v1.0**: Multiplayer over the network.
- Improved graphics and sound effects.
- Cross-platform releases.

---

## Contributions
Feel free to contribute to the project or provide feedback. Submit a pull request or open an issue to get started.

---

Thank you for checking out SSPC! Your support and interest inspire future development.

---


# Systemd Service Manager Script

A unified, interactive, color-coded Bash shell utility to search, audit, track, and manipulate systemd services seamlessly from your command line.

## 🚀 Key Features

*   **Default Boot Auditing:** Runs a system-wide lookup of boot-enabled services if no arguments are provided.
*   **Targeted Search Engine (`-s`):** Pulls a granular live metadata breakdown for a specific service including Description, Main PID, exact Memory footprint calculation, and untruncated absolute binary Exec paths.
*   **State-Aware Colorization:** Outputs dynamic statuses with color configurations (**Bright Green** for running/enabled states, **Red** for dead/disabled/masked states).
*   **Persistent & Runtime Manipulation:** Instantly **Start (`-t`)**, **Kill/Stop (`-k`)**, or **Disable from boot (`-d`)** any system unit cleanly using automatic sudo execution hooks.
*   **Text Processing Consistency:** Built without relying on internal systemctl pagers (`--no-pager`), enabling stable output streams for logs or upstream automation pipelines.

---

## 🛠️ Options and Flags

Execute the script alongside the following structural arguments:

| Short Flag | Long Flag | Required Value | Functionality Description |
| :--- | :--- | :--- | :--- |
| **`-b`** | `--boot` | *None* | Lists all services persistently configured to launch at machine boot (**Default Behavior**). |
| **`-r`** | `--running` | *None* | Queries and displays all system units actively executing tasks in system memory. |
| **`-a`** | `--active` | *None* | Expands the scope to show all active services (running, waiting, or exited cleanly). |
| **`-s`** | `--search` | `NAME` | Profiles a single unit's structural configuration and live performance stats. |
| **`-t`** | `--start` | `NAME` | Spawns and initializes an inactive service by name via root authorization. |
| **`-k`** | `--kill` | `NAME` | Drops and terminates an active service parent execution tree cleanly. |
| **`-d`** | `--disable` | `NAME` | Breaks persistence symlinks to prevent a service from starting on system initialization. |
| **`-v`** | `--verbose` | *None* | Appends detailed text summaries underneath batch unit lists. |
| **`-h`** | `--help` | *None* | Spawns the command map manual. |

---

## 💻 Technical Implementation Details

1.  **POSIX Compliant Case Shifting:** Built using a custom dynamic parameter loop mapping (`while [[ $# -gt 0 ]]`), supporting both short flags (`-s`) and descriptive long options (`--search`).
2.  **Explicit Normalization:** Input queries are evaluated safely. Passing arguments like `nginx` or `bluetooth` are automatically sanitized to `nginx.service` or `bluetooth.service` respectively before interfacing with the systemd socket.
3.  **Advanced RegEx Tokenizing:** Uses targeted `awk` delimiter slicing (`-F' path='`) to unpack binary configurations from nested systemd system property schemas without clipping or truncation.
4.  **Memory Footprint Calculation:** Automatically sniffs raw metric structures (`MemoryCurrent`), discarding non-initialized integer patterns (`18446744073709551615`), and parses base bytes into megabytes (MB) cleanly.

---

## 📦 Usage Examples

```bash
# Display the standard boot-enabled services log
./services.sh

# Profile a specific daemon with live stats and untruncated binary properties
./services.sh --search docker

# Terminate a service and pull the list of remaining running units sequentially
./services.sh -k apache2 --running

# Enable verbose summaries for active services
./services.sh -a -v
```

---

## 📋 Installation Prerequisites

Ensure execution bits are set on your script before initializing:

```bash
chmod +x services.sh
```
*Note: Service modification parameters (`-t`, `-k`, `-d`) implicitly require administrative permissions and will request `sudo` elevation during processing.*

import subprocess
import os
from pyrogram import Client, filters
from pyrogram.types import Message

# Pyrogram bot configuration
app = Client(
    "my_bot",
    api_id="YOUR_API_ID",  # Tumhara Telegram API ID
    api_hash="YOUR_API_HASH",  # Tumhara Telegram API Hash
    bot_token="YOUR_BOT_TOKEN"  # Tumhara BotFather se mila token
)

 - Show this help\n/io_status - Check Io script status")

@app.on_message(filters.command("io_status"))
async def io_status(client: Client, message: Message):
    if io_process and io_process.poll() is None:
        await message.reply_text("Io script is running.")
    else:
        await message.reply_text("Io script is not running. Restarting...")
        global io_process
        io_process = start_io_script()

# Main function to run the bot
if __name__ == "__main__":
    # Start the Io script when the Python script starts
    io_process = start_io_script()

    # Start the Pyrogram bot
    print("Starting Pyrogram bot...")
    app.run()




import os
import subprocess
import sys
import platform

def install_sbcl():
    system = platform.system().lower()
    try:
        if system == "linux":
            if os.system("which apt-get") == 0:
                print("Installing SBCL using apt-get...")
                result = os.system("sudo apt-get update && sudo apt-get install -y sbcl")
            elif os.system("which yum") == 0:
                print("Installing SBCL using yum...")
                result = os.system("sudo yum install -y sbcl")
            elif os.system("which pacman") == 0:
                print("Installing SBCL using pacman...")
                result = os.system("sudo pacman -S --noconfirm sbcl")
            elif os.system("which zypper") == 0:
                print("Installing SBCL using zypper...")
                result = os.system("sudo zypper install -y sbcl")
            else:
                print("No supported package manager found. Please install SBCL manually.")
                return False
        elif system == "windows":
            print("Windows detected. Please download and install SBCL from: http://www.sbcl.org/platform-table.html")
            print("Or use chocolatey: choco install sbcl")
            return False
        else:
            print(f"Unsupported operating system: {system}")
            return False
        return result == 0
    except Exception as e:
        print(f"Error installing SBCL: {e}")
        return False

def check_sbcl_installed():
    try:
        result = subprocess.run(["sbcl", "--version"], 
                              capture_output=True, 
                              text=True, 
                              timeout=10)
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False

def start_script():
    try:
        if not check_sbcl_installed():
            print("SBCL not found. Attempting to install...")
            if install_sbcl():
                print("SBCL installation completed. Checking again...")
                if not check_sbcl_installed():
                    print("SBCL installation failed or not accessible in PATH.")
                    return None
            else:
                print("Failed to install SBCL automatically.")
                return None
        print("SBCL found. Starting Lisp script...")
        process = subprocess.Popen(
            ["sbcl", "--script", "app.lisp"], 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE
        )
        print(f"Lisp script started with PID: {process.pid}")
        return process
    except Exception as e:
        print(f"Error starting Lisp script: {e}")
        return None


@app.on_message(filters.command("start"))
async def start_command(client: Client, message: Message):
    await message.reply_text("Hello! I'm the Lisp bot. /lisp_status - To check lisp script status.")

@app.on_message(filters.command("io_status"))
async def io_status(client: Client, message: Message):
    if io_process and io_process.poll() is None:
        await message.reply_text("Lisp script is running.")
    else:
        await message.reply_text("Lisp script is not running. Restarting...")
        global io_process
        io_process = start_script()
        await message.reply_text(f"<pre>{io_process}</pre>")


app.run()
io_process = start_script()
if io_process:
    print("Lisp script is running...")

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

# Io script ka path
IO_SCRIPT_PATH = "telegram_bot.io"


def start_io_script():
    try:
        if not os.system("sbcl --version"):
            process = subprocess.Popen(["sbcl", "--script", "telegram_bot.lisp"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print(f"Lisp script started with PID: {process.pid}")
            return process
        else:
            print("SBCL is not installed or not found in PATH.")
            return None
    except Exception as e:
        print(f"Error starting Lisp script: {e}")
        return None



# Function to start the Io script
def start_io_script():
    try:
        # Check if Io is installed
        if not os.system("io --version"):
            # Run the Io script in the background
            process = subprocess.Popen(["io", IO_SCRIPT_PATH], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print(f"Io script started with PID: {process.pid}")
            return process
        else:
            print("Io is not installed or not found in PATH.")
            return None
    except Exception as e:
        print(f"Error starting Io script: {e}")
        return None

# Pyrogram command handlers
@app.on_message(filters.command("start"))
async def start_command(client: Client, message: Message):
    await message.reply_text("Hello! I'm the Pyrogram bot. Use /help for commands.")

@app.on_message(filters.command("help"))
async def help_command(client: Client, message: Message):
    await message.reply_text("Commands:\n/start - Start the bot\n/help - Show this help\n/io_status - Check Io script status")

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

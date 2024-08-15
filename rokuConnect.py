import requests

# Replace this with the IP address of your Roku TV
ROKU_IP = '192.168.1.100'  # Example IP address
ROKU_PORT = 8060  # Default Roku ECP port

# Base URL for ECP commands
BASE_URL = f'http://{"IP"}:{"Port"}'

def send_command(command):
    """
    Send a command to the Roku TV.
    :param command: Command to send (e.g., 'keypress/Home', 'keypress/Power', 'keypress/VolumeUp', etc.)
    """
    url = f'{BASE_URL}/{command}'
    response = requests.post(url)
    if response.status_code == 200:
        print(f'Successfully sent command: {command}')
    else:
        print(f'Failed to send command: {command}, Status Code: {response.status_code}')

def power_on():
    send_command('keypress/PowerOn')

def power_off():
    send_command('keypress/PowerOff')

def volume_up():
    send_command('keypress/VolumeUp')

def volume_down():
    send_command('keypress/VolumeDown')

def mute():
    send_command('keypress/VolumeMute')

def home():
    send_command('keypress/Home')

def launch_app(app_id):
    """
    Launch an app on the Roku TV.
    :param app_id: The ID of the app to launch (e.g., Netflix ID is '12')
    """
    send_command(f'launch/{app_id}')

# Example usage
if __name__ == '__main__':
    home()          # Go to the home screen
    power_on()      # Power on the TV
    volume_up()     # Increase volume
    launch_app(12)  # Launch Netflix (example app ID)

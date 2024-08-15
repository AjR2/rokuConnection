import socket
import requests
from xml.etree import ElementTree as ET

def discover_roku_devices():
    """
    Discover Roku devices on the local network using SSDP.
    """
    SSDP_GROUP = ('239.255.255.250', 1900)
    MSEARCH_MSG = (
        'M-SEARCH * HTTP/1.1\r\n' +
        'HOST: 239.255.255.250:1900\r\n' +
        'MAN: "ssdp:discover"\r\n' +
        'MX: 1\r\n' +
        'ST: roku:ecp\r\n' +
        '\r\n'
    )

    # Create a socket for UDP multicast
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.settimeout(2)
    sock.sendto(MSEARCH_MSG.encode('utf-8'), SSDP_GROUP)

    roku_devices = []

    try:
        while True:
            data, addr = sock.recvfrom(1024)
            if 'roku:ecp' in data.decode('utf-8'):
                roku_devices.append(addr[0])
    except socket.timeout:
        pass

    return roku_devices

def get_roku_info(ip):
    """
    Get Roku device info using the ECP API.
    :param ip: IP address of the Roku device.
    """
    url = f'http://{ip}:8060/query/device-info'
    response = requests.get(url)
    if response.status_code == 200:
        xml_root = ET.fromstring(response.content)
        for elem in xml_root.iter():
            print(f'{elem.tag}: {elem.text}')
    else:
        print(f'Failed to get info from Roku device at {ip}')

if __name__ == '__main__':
    devices = discover_roku_devices()
    if devices:
        print('Found Roku devices:')
        for ip in devices:
            print(f' - {ip}')
            get_roku_info(ip)
    else:
        print('No Roku devices found.')

#

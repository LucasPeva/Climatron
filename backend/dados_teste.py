import requests
import random
import time


url = 'http://127.0.0.1:5000/sensor-data'  # IP backend

def generate_random_data():
    temperature = round(random.uniform(20.0, 30.0), 2)  # Temperatura entre 15 e 30 graus
    humidity = round(random.uniform(30.0, 60.0), 2)      # Umidade entre 30% e 70%
    return {
        'temperature': temperature,
        'humidity': humidity
    }

def send_data():
    while True:
        data = generate_random_data()
        response = requests.post(url, json=data)
        if response.status_code == 201:
            print(f'Dados enviados: {data}')
        else:
            print(f'Erro ao enviar dados: {response.status_code}, {response.text}')
        time.sleep(1)  # Envia dados a cada 10 segundos

if __name__ == '__main__':
    send_data()

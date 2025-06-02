# Importa as bibliotecas
from dotenv import load_dotenv
from flask import Flask, request, jsonify
from flask_cors import CORS
from supabase import create_client, Client
import os

# Cria o app Flask e permite o CORS nele
app = Flask(__name__)
CORS(app)

# Pega as variáveis de ambiente
load_dotenv()
SUPABASE_URL = str(os.environ.get('SUPABASE_URL'))
SUPABASE_KEY = str(os.environ.get('SUPABASE_KEY'))

# Cria a conexão com  o banco de dados no Supabase
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Rota de POST para salvar os dados
@app.route('/sensor-data', methods=['POST'])
def receive_sensor_data():
    data = request.json
    temperature = data.get('temperature')  # type: ignore
    humidity = data.get('humidity') # type: ignore
    
    if temperature is None or humidity is None:
        return jsonify({'error': 'Missing temperature or humidity data'}), 400
        
    insert_data = {
        'temperature': temperature,
        'humidity': humidity,
    }
    
    response = supabase.table('readings').insert(insert_data).execute()
    
    return jsonify({'message': "Data saved successfully"}), 201

@app.route('/latest', methods=['GET'])
def get_latest_reading():
    response = supabase.table('readings').select('*').order('timestamp', desc=True).limit(1).execute()
    
    
    data = response.data
    if not data:
        return jsonify({'message': 'No data found'}), 404
    
    latest = data[0]
    
    return jsonify({
        'timestamp': latest.get('timestamp'),
        'temperature': latest.get('temperature'),
        'humidity': latest.get('humidity')
    })

@app.route('/history', methods=['GET'])
def get_history():
    limit = 100
    
    response = supabase.table('readings').select('*').order('timestamp', desc=True).limit(limit).execute()
    data = response.data
    return jsonify(data)

@app.route('/averages', methods=['GET'])
def get_averages():
       
    response = (
        supabase.table('daily_averages')
        .select('*')
        .order('id', desc=True)
        .execute()
        )
    data = response.data
    return jsonify(data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
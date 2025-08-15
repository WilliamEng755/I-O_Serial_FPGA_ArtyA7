import serial
import time

ser = serial.Serial('COM4', 9600, timeout=1)
time.sleep(2)



ser.write(b'Teste entrada e saida 123\n')
time.sleep(1)


# Tenta ler por até 5 segundos
for i in range(5):
    resposta = ser.read(100)
    if resposta:
        print(f"Recebido: {resposta.decode('utf-8')}")
        break
else:
    print("Nenhuma resposta recebida.")
ser.close()

# I/O Serial FPGA Arty A7

Este projeto contém arquivos Verilog e Python para comunicação serial entre um computador e a FPGA Arty A7. O objetivo é enviar dados via UART para a FPGA, que os interpreta e realiza ações específicas.

## Estrutura do Projeto

- `/verilog`: Módulos Verilog para recepção e interpretação de dados seriais (loopback, UART_TX, UART_TX)
- `/python`: Scripts Python para envio de dados via porta serial (index)


## Como Usar

1. Compile e grave o código Verilog na FPGA usando Vivado
2. Execute o script Python para enviar dados via porta serial
3. A FPGA interpreta os dados e realiza a ação correspondente


## Explicação do script python

Na linha ser = serial.Serial('COM4', 9600), a porta 'COM4' refere-se à porta serial do seu computador. Pode ser que, no seu caso, ela seja exatamente 'COM4', mas também pode variar. Quando você conectar a placa à sua máquina, abra o Gerenciador de Dispositivos e verifique qual é o nome da porta atribuída. Depois, substitua 'COM4' pelo nome correto da sua porta serial.

Na linha ser.write(b'Teste entrada e saida 123\n') tem que usar o '\n', onde ele é é um caractere ASCII (0x0A) usado como marcador de fim de mensagem na comunicação serial.
Sem ele, a FPGA não sabe onde a frase termina e pode juntar dados ou mandar lixo no retorno.
Com ele, o firmware detecta o fim, processa e limpa o buffer corretamente.
É como dizer “ponto final” para a placa saber que pode responder.

O valor dentro de ser.read(100) é apenas o limite máximo de bytes que será lido de uma vez.
Você pode colocar qualquer valor, como 50, 100, 200, etc., dependendo do tamanho máximo que espera receber.
Se chegar menos bytes do que o valor definido, ele retorna apenas o que tiver recebido antes do timeout.


É necessário mudar o path do ficheiro de logs no Cliente e no CreateAccounts conforme a máquina que está a correr o programa.
Os ficheiros de servidor precisam de estar na pasta usr, em Erlang OTP, no computador que o vai correr.
Para testar em computadores diferentes, é preciso mudar o primeiro campo no método Socket (no ficheiro Cliente.pde) para o IP da máquina que está a correr o servidor.
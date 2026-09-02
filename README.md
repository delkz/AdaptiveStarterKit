# Adaptive Starter Kit (Build 42)

Um mod para Project Zomboid que fornece a personagens novos um kit inicial coerente com o tempo decorrido no mundo.

## Progressão padrão

| Idade do mundo | Kit possível |
| --- | --- |
| 0–3 dias | Nenhum item |
| 4–7 dias | Água e um lanche simples |
| 8–14 dias | Mochila escolar, água, comida e arma improvisada |
| 15–30 dias | Mochila, suprimentos médicos, comida e arma corpo a corpo usada |
| 31–60 dias | Mochila melhor, ferramentas, suprimentos e arma usada |
| 61+ dias | Kit de sobrevivente; pequena chance de arma de fogo |

Os itens com condição possuem desgaste aleatório. Armas de fogo não recebem munição por padrão, mantendo a morte relevante.

## Instalação local

1. Extraia a pasta `AdaptiveStarterKit` em:
   `C:\Users\SEU_USUARIO\Zomboid\mods\`
2. Ative **Adaptive Starter Kit** no menu de mods.
3. Ao criar um mundo, procure a seção **Adaptive Starter Kit** nas opções Sandbox.

## Servidor dedicado

Copie `AdaptiveStarterKit` para a pasta de mods do servidor e adicione:

```ini
Mods=AdaptiveStarterKit
```

Se publicar no Steam Workshop, adicione também o respectivo Workshop ID em `WorkshopItems`.

## Configuração

As opções Sandbox permitem:

- ativar ou desativar o mod;
- escolher os dias que separam os seis estágios;
- multiplicar a quantidade de suprimentos;
- definir a chance de arma de fogo no estágio final;
- ativar mensagens de diagnóstico no console.

Alterar os limites afeta somente personagens criados depois da mudança.

## Observações

- Cada personagem recebe o kit apenas uma vez.
- O mod usa apenas itens vanilla.
- Em multiplayer, o estágio é baseado na idade do mundo do servidor.
- O código do kit está em `42/media/lua/client/ASK_Main.lua` e pode ser ajustado facilmente.


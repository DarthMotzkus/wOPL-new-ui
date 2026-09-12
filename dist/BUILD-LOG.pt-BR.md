# wOPL Build Changelog

> **Note — this file is in Portuguese, unlike the rest of the repository.** It is the
> author's running log of local builds, written as each one was made, and it is kept
> verbatim: translating it after the fact would risk rewriting technical notes that are
> relied on. New entries may be written in either language. Everything else in this
> repository — `README.md`, `docs/`, commit messages, release notes — is English.

Histórico de builds locais com análise prática das mudanças do upstream. Mais recente no topo.

---

## 2026-09-12 18:45 — `v1.2-beta-447-20260625-105850-988-ce94bd9-dirty` — 1.561.636 bytes (`ce94bd9`)

**Correção: o último jogo copiado nunca era lembrado como "last played".** Sem mudança de upstream (build sem pull, por decisão — os 19 commits da origin continuam parados até sair versão estável).

Diagnóstico: ao montar a lista, o wOPL marca o jogo lembrado e levanta uma flag interna (`remindLast`); a ordenação alfabética que vem logo depois só respeita a seleção se essa flag estiver levantada. Só que o **primeiro item da lista crua** entrava por um ramo `else if` que já o selecionava por ser o primeiro — e nunca levantava a flag. A ordenação então jogava o cursor de volta pro topo. Como a varredura de pasta empilha os arquivos ao contrário, o "primeiro da lista crua" é justamente a **última ISO copiada** — no caso, o `SLPM_660.73`. Efeito colateral do mesmo ramo: a contagem regressiva do auto-start também não disparava para esse jogo.

Correção em `src/gui.c` (`GUI_OP_APPEND_MENU`): o `else if` virou um `if` independente, então a flag sobe também quando o jogo lembrado é o primeiro da lista. Nenhum outro caso muda de comportamento. Patch novo e separado: `patches/gui.c.remember-last.patch` (convive com o `gui.c.patch` do `guiDrawBGSettings` — apply real verificado nos dois, em sequência).

**Mudança no processo de build:** o `git pull` deixou de ser automático. O script agora compila o checkout como está e só sincroniza com a origin se receber `--pull` (ou `WOPL_PULL=1`). `SKILL.md` atualizado com aviso pra nunca puxar por iniciativa própria.

⚠️ Testar no PS2: jogar o `SLPM_660.73`, desligar e religar — ele deve abrir destacado, e com auto-start ligado a contagem deve aparecer. Não corrige a aba Favoritos (nunca lembra, caminho separado) nem a troca automática de aba quando o jogo está em outro device.

---

## 2026-06-27 21:12 — `v1.2-beta-447-...-ce94bd9-dirty` — 1.561.892 bytes (`ce94bd9`)

**Restauração das posições de assets do tema (lista) a partir do ELF antigo.** Sem mudança de upstream.

O `OPL_old.ELF` (build antiga "correta") foi **desempacotado** (ps2-packer/LZMA, calibrado com o próprio packer do toolchain) e os theme cfgs embutidos extraídos. Comparando, o drift estava só no `misc/theme_list.cfg`. Restaurado para o padrão antigo via `theme_list.cfg.patch` regenerado:
- ItemsList (lista): `x=20 y=57 h=342` (era 40/38/380)
- ItemCover (capa/box): `x=-61 y=-271`; apps `x=-61 y=-199` (era -106/-296 e -106/-224)
- ItemIcon (ícone da mídia/disc): `x=-245 y=-195 wsX=-210` (era -240/-210/-205)
- Removida a sombra `lm_case_shadow` (não existia no antigo) + renumeração
- Já estavam corretos: ID do jogo (ItemText -94/-130), Loading (y=-80), reflexos (off). Cores (common.c) e coverflow: sem drift.

Referência-ouro salva na skill (`reference/`) pra não se perder de novo. ⚠️ Testar no PS2.

---

## 2026-06-27 12:27 — `v1.2-beta-447-...-ce94bd9-dirty` — 1.561.748 bytes (`ce94bd9`)

**Rebuild limpo.** Nenhuma mudança do upstream desde a build anterior — só re-aplica os 7 patches locais (sem instrumentação, sem alteração de código). Mesmos `config_wopl`/`supportbase` que implementam a leitura per-game do `CFG/cfg.tar`. Gerado a pedido pra recopiar pra pasta BOOT na mc1. ⚠️ A teoria do código pra ler o `.tar` continua correta; pendente confirmar no PS2 por que o `cfg_cache.bin` nunca nasce no mmce1 (ver investigação na sessão).

---

## 2026-06-27 — `v1.2-beta-447-...-ce94bd9-dirty` — 1.561.748 bytes (`ce94bd9`)

**Fix local (patches nossos) — leitura de config por jogo do `CFG/cfg.tar`.**

Sem mudança de upstream. Restaura a leitura do `cfg.tar` no caminho per-game, que a migração libconfig do upstream tinha **órfãado** (regressão).

- **Causa:** o build novo definia `TAR_KIND_CFG` no `tar.c` mas **nada o consumia** — o loader per-game (`wOPLPerGameLoad`) só lia `CFG/<id>.cfg` solto. O build antigo lia do `cfg.tar` (`tarFind`/`tarRead`). ART e CHT continuavam lendo do tar; só o CFG ficou de fora.
- **Fix:** novo `wOPLPerGameLoadBuf()` em `config_wopl.c` (parse de buffer via `config_read_string`, **formato libconfig/novo apenas**), e fallback no `sbPopulateConfig()` (`supportbase.c`): tenta `CFG/<id>.cfg` solto → senão lê do `CFG/cfg.tar` via `tarFind/tarGet(TAR_KIND_CFG)`. O tar carrega sob demanda igual ART/CHT.
- 7 patches no total aplicando limpo. ⚠️ O `cfg.tar` precisa conter configs no **formato novo** (libconfig) — migrar antes com a opção *Config Migration* e repackar.
- ⚠️ **Testar no PS2.**

---

## 2026-06-27 00:22 — `v1.2-beta-447-...-ce94bd9-dirty` — 1.561.780 bytes (`ce94bd9`)

**Fix local (patch nosso) — gravação de settings no cartão de memória.**

Sem mudança de upstream. Esta build adiciona uma correção no `config_wopl.c.patch` para o bug de **"erro ao gravar settings"** em setups com dois cartões.

- **Causa:** o sistema de config novo do upstream (migração libconfig) usa `sysCheckMC()` pra achar o slot do MC, que escolhe cegamente o **primeiro slot com cartão** (prefere mc0). Em quem tem um cartão comum na mc0 **e** o MMCE/config na mc1, ele mirava a mc0 errada (onde a pasta `wOPL_1_2/` não existe) → falhava ao criar a pasta/gravar. O código antigo usava `sbGetmcID()`, que prefere o slot **que tem a pasta** — por isso gravava antes.
- **Fix:** helper local `wopl_mc_slot()` no `config_wopl.c` (read-only, sem efeito colateral) que checa os dois slots preferindo o que já tem a pasta `wOPL_1_2/`, e substitui os 3 usos de `sysCheckMC()`. Agora grava na mc1 (onde a config vive), sem precisar criar pasta.
- ⚠️ **Testar no PS2:** confirmar que as settings salvam de fato na mc1 sem erro.

---

## 2026-06-26 22:40 — `v1.2-beta-447-20260625-105850-988-ce94bd9-dirty` — 1.561.668 bytes (`ce94bd9`)

Nenhuma mudança do upstream desde a build anterior — rebuild só pra validar o novo versionamento de saída (build atual `opl-<rev>.ELF` na raiz, anteriores arquivadas em `old\`). Os mesmos patches locais foram reaplicados.

---

## 2026-06-26 22:28 — `v1.2-beta-447-20260625-105850-988-ce94bd9-dirty` — 1.561.668 bytes (`ce94bd9`)

**Mudanças do upstream desde a build anterior** (`87bc893`, 09/06 01:22):
24 commits, 80 arquivos, +7012/−3702 linhas. Atualização **grande**, com uma reescrita interna pesada.

### O que tem de novo na prática

- **Sistema de config reescrito pra libconfig.** A maior mudança: o `config.c` interno virou `config_migration.c` + `config_wopl.c`, e o `conf_opl.cfg` (e os temas) passaram pro formato libconfig (`chave = "valor";`). O global cfg agora é compatível com pademu, GSM e cheat. Mudança interna grande, mas o efeito prático é config mais robusta — e foi o que obrigou a refazer nossos patches de tema do zero.

- **Game ID removido do tema padrão.** O upstream tirou o game ID da lista principal (a pedido do Berion). **Nós restauramos via patch** — continua aparecendo normalmente na sua build.

- **Frame delay pode ser zero.** Agora dá pra setar delay 0 nas fontes (antes voltava pro mínimo de 8). Aproveitamos isso no nosso patch novo: o **MMCE agora carrega as capas instantaneamente** (sem aquele pré-delay antes da capa aparecer).

- **Suporte a Neutrino e VMC ampliado.** Novo `neutrino_loader`, atualização do path do Neutrino e suporte a VMC. Apps passaram a usar o "sb helper" e os defines do core loader.

- **Menu e controle mais polidos.** Navegação desabilitada na tela de info, carregamento da config do item otimizado (fora do render lock / só na info page), e correção no timing do repeat do direcional quando o contador da CPU dá wrap.

- **Tema/UI variados.** Disc art virou toggle em runtime, hints de submenu usam o `textColor`, créditos do "about" alfabetizados e nome corrigido.

- **Splash e versão.** Notificações no boot (splash) e texto de versão na tela.

- **Diversos.** Correção no probing de dispositivo do tar, limpeza de funções de BGM comentadas.

- **gfx do upstream:** removeram vários ícones antigos (`Device_*`, `Scan_*`, `Vmode_multi`) e renomearam `Vmode_ntsc/pal` → `Region_ntsc/pal`. Não afeta nossos customs (`disc`, `lm_case`, `settings_bg`).

> ⚠️ **Overlap:** o upstream também mexeu em arquivos que nossos patches modificam — `misc/theme_list.cfg`, `misc/theme_coverflow.cfg`, `src/config_wopl.c` e `src/gui.c`. Os dois temas foram **reescritos do zero no formato libconfig novo** (incluindo restaurar o game ID e desligar o reflexo no coverflow), e tudo aplicou limpo, sem conflito. Mesmo assim, **vale conferir no PS2/emulador** se a lista (game ID, fundo em camadas) e o coverflow ficaram visualmente OK.

---

## 2026-06-09 01:22 — `v1.2-beta-423-20260604-135718-925-87bc893-dirty` — 1.567.460 bytes (`87bc893`)

**Mudanças do upstream desde a build anterior** (`8a1a583`, 26/05 22:16):
17 commits, 44 arquivos, +668/−321 linhas. Esta foi uma atualização grande.

### O que tem de novo na prática

- **Coverflow bem mais maduro.** Vários commits mexeram no modo coverflow: correção de um crash ao selecionar item, um novo som de navegação exclusivo do coverflow (`audio/coverflow.adp`), ajuste de proporção dos itens de APP no modo Favoritos, e um novo parâmetro `coverflow_cover_offset` nos temas (já aparece no `theme_coverflow.cfg` atualizado). No geral: coverflow mais estável e com áudio/posicionamento próprios.

- **Ícones para PadEmu, GSM e Cheat.** Foram adicionados ícones novos (`pademu_on/off`, `gsm_on/off`, `cht_on/off`) e os temas ganharam seções `info18/19/20` que mostram, no painel de informações do jogo, se Emulação de Controle, GSM e Cheats estão ligados. Antes esses estados não tinham indicador visual.

- **Cálculo do tamanho do jogo no boot.** O tamanho do jogo passa a ser calculado já na inicialização, então o atributo `#Size` no painel de info aparece preenchido de forma mais confiável.

- **Envio do Game ID para MMCE corrigido.** Dispositivos MMCE (MemCard Pro, SD2PSX) agora recebem o ID do jogo corretamente — importante pra quem usa pastas/saves por jogo nesses cartões.

- **Logo e SDK: idas e vindas internas.** Houve uma sequência de commits revertendo a logo animada (apng) de volta pra logo antiga e voltando o ps2sdk pra uma versão mais antiga por estabilidade. O `gfx/logo.png` foi removido do repositório (a logo agora é tratada de outro jeito). Efeito prático: logo de boot estável; sem novidade visual garantida.

- **"Various Fixes" + ajustes diversos.** Um lote grande de correções espalhadas (rede/nbd, suporte a HDD/ETH/BDM, menus, diálogos, renderização). São majoritariamente correções de estabilidade sem mudança óbvia de uso. Atualizações de README e do CI de compilação não afetam o uso.

### ⚠️ Atenção — patches locais vs. upstream

O upstream também mexeu em **três arquivos que os nossos patches modificam**:

- **`misc/theme_coverflow.cfg`** e **`misc/theme_list.cfg`** — tiveram conflito de merge nesta build e foram **resolvidos à mão por mim**. Mantive as suas customizações (cores `#000000`/`#B0B300`/`#0079F5`, `pattern=BG` + StaticImage do `settings_bg`, `reflection=0`, reposicionamentos) E as novidades do upstream (o `coverflow_cover_offset=14`, os pequenos ajustes de coordenadas de overlay e as novas seções `info18/19/20` dos ícones PadEmu/GSM/Cheat). Os dois `.patch` foram **regenerados** sobre a base nova, então as próximas builds aplicam limpo. **Vale conferir no PS2** se o coverflow e a lista ficaram visualmente OK — principalmente o alinhamento dos covers e se os novos ícones de status aparecem direito.
- **`src/gui.c`** — o `git apply --3way` resolveu sozinho; sem conflito, mas como o upstream também editou, vale um olhar rápido se a sua customização de GUI continua se comportando.

## 2026-05-26 22:16 — `v1.2-beta-403-20260526-091632-872-8a1a583-dirty` — 1.556.612 bytes (`8a1a583`)

**Mudanças do upstream desde a build anterior** (`397a1f0`, 25/05 21:34):
1 commit, 2 arquivos, +5/−1 linhas.

### O que tem de novo na prática

- **Suporte a PNG em tons de cinza (grayscale e grayscale+alpha)** — o carregador de texturas (`src/textures.c`) agora aceita PNGs no modo grayscale e grayscale+alpha, além dos formatos que já lia (RGB/RGBA/indexado). Na prática: imagens em tons de cinza com ou sem transparência passam a carregar corretamente em vez de falhar/distorcer. **Esse commit é a sua própria contribuição** — o Wolf3s mergeou o patch creditando @DarthMotzkus e fechando a issue #225. O resto do commit é só atualização do README. Vale notar pro fluxo do `bg-wopl`: PNGs grayscale agora são uma opção válida pra backgrounds/texturas, não só indexado 8-bit.

### Conflito com patches locais?

Nenhum. O upstream só mexeu em `src/textures.c` e `README.md` — nenhum dos nossos quatro patches (`common.c`, `gui.c`, `theme_list.cfg`, `theme_coverflow.cfg`) toca esses arquivos. Todos aplicaram limpos via `git apply --3way`.

### Patches locais aplicados nesta build

- `common.c.patch` — cores padrão (bg/text/ui/sel/plasma)
- `gui.c.patch` — `guiDrawBGSettings` retorna 0 (Settings sem `settings_bg`)
- `theme_list.cfg.patch` — tema da lista (camadas BG/overlay, posições, cores, sem reflection no disco, sem sombra na capa, 18 itens visíveis)
- `theme_coverflow.cfg.patch` — tema coverflow (cores, sem reflection nos cases)

---

## 2026-05-25 21:34 — `v1.2-beta-402-20260525-090344-871-397a1f0-dirty` — 1.556.644 bytes (`397a1f0`)

**Mudanças do upstream desde a build anterior** (`2f02bd3`, 24/05 11:49):
8 commits, 32 arquivos, +142/−34 linhas.

### O que tem de novo na prática

- **Logo animado de volta** — Wolf3s reimplementou o logo animado do menu principal, com 21 frames (`gfx/logo_01.png` … `logo_21.png`). Mudanças em `menusys`, `textures`, `themes`, `gui.c` e `guigame.c` cuidam de carregar e tocar a animação. Testado com outros temas segundo o autor, então deve conviver bem com `theme_list` e `theme_coverflow`. Se o seu `logo.png` local sobrescrever só o frame estático, o resto da animação continua vindo do upstream — você pode trocar frames individuais depois pelo overlay de `gfx/` se quiser.
- **Coverflow melhorado (#230)** — KrahJohlito mexeu no tema coverflow. Os commits de README do André Guilherme só documentam o que mudou e o uso de `art.tar`, sem efeito no binário. Vale conferir como ficou o coverflow no PS2 — especialmente porque nosso `theme_coverflow.cfg.patch` ainda fixa cores e desativa reflection.
- **Bug fix: reset do core loader entre jogos (#228)** — uma variável local do carregador de núcleos não era resetada antes de ler o `.cfg` por jogo, então config de um jogo podia "vazar" pro próximo lançado na mesma sessão. Bug real de quem alterna jogos com configs diferentes; agora corrigido.
- **Infra/limpeza** — atualização dos badges de CI (#231) e fix do badge de Codacy (#227) no README, e remoção de libs antigas no raiz do repo. Zero impacto no PS2.

### Conflito com patches locais?

**Atenção:** o upstream **também mexeu em `src/gui.c`** (para encaixar o logo animado e o coverflow). Nosso `gui.c.patch` (que faz `guiDrawBGSettings` retornar 0 pra Settings sem `settings_bg`) aplicou limpo via `git apply --3way`, mas vale **testar no PS2 real** se:
1. O logo animado aparece corretamente no menu principal;
2. A tela de Settings continua sem o `settings_bg` (nosso patch ainda surte efeito);
3. A navegação no coverflow não regrediu.

Os outros três patches (`common.c`, `theme_list.cfg`, `theme_coverflow.cfg`) tocam arquivos que o upstream não modificou nesta janela, então aplicaram sem fricção.

### Patches locais aplicados nesta build

- `common.c.patch` — cores padrão (bg/text/ui/sel/plasma)
- `gui.c.patch` — `guiDrawBGSettings` retorna 0 (Settings sem `settings_bg`) — **revisar contra a mudança upstream em `src/gui.c`**
- `theme_list.cfg.patch` — tema da lista (camadas BG/overlay, posições, cores, sem reflection no disco, sem sombra na capa, 18 itens visíveis)
- `theme_coverflow.cfg.patch` — tema coverflow (cores, sem reflection nos cases)

---

## 2026-05-24 11:49 — 1.516.772 bytes (`2f02bd3`)

**Mudanças do upstream desde a build anterior** (`252c77d`, 24/05 03:30):
4 commits, 15 arquivos, +558/−441 linhas.

### O que tem de novo na prática

- **Carregamento sob demanda de TAR (ART / CFG / CHT)** — o grande commit deste ciclo. O sistema que lê os tarballs de capas de jogos (`ART/art.tar`), configurações de jogo e cheats foi reescrito para carregar os arquivos **só quando precisar** em vez de processar o tarball inteiro de uma vez. Em termos práticos: menos memória usada na lista de jogos e provavelmente menor delay quando você tem ART/CHT/CFG grandes. O arquivo interno mudou de nome (`art_tar.c` → `tar.c`), por isso aparecem tantos arquivos como modificados.
- **Adaptação dos backends de device ao novo loader** — `BDM` (USB/MMC), `ETH` (rede SMB), `HDD` (HDD interno) e `MMCE` (cartão MMCE) foram ajustados pra falar com o novo carregador de TAR. Para o usuário final é transparente: continuam funcionando do mesmo jeito, só que internamente passam pelo loader novo.
- **Limpeza interna** — remoção de headers TAR que não eram mais usados e correção de warnings do compilador. Sem efeito visível.
- **Infra/docs** — fix no badge de CI no README e atualização do README sobre o novo loader. Zero impacto no PS2.

### Conflito com patches locais?

Nenhum. O upstream não mexeu em `src/common.c`, `src/gui.c`, `misc/theme_list.cfg` nem `misc/theme_coverflow.cfg` — todos os nossos patches aplicaram limpos via `git apply --3way`.

### Patches locais aplicados nesta build

- `common.c.patch` — cores padrão (bg/text/ui/sel/plasma)
- `gui.c.patch` — `guiDrawBGSettings` retorna 0 (Settings sem `settings_bg`)
- `theme_list.cfg.patch` — tema da lista (camadas BG/overlay, posições, cores, sem reflection no disco, sem sombra na capa, 18 itens visíveis)
- `theme_coverflow.cfg.patch` — tema coverflow (cores, sem reflection nos cases)

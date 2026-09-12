# wOPL — posições de assets do tema (referência-ouro)

Fonte da verdade para as customizações de posição/layout do usuário, **independente** de
como os patches em `to build wOPL/patches/` estejam (mudaram, foram refatorados, etc.).

Origem: extraídas do build antigo conhecido-correto (`OPL_old.ELF`, desempacotado via
ps2-packer/LZMA em jun/2026). Confirmadas e embutidas no build `ce94bd9`.

## Arquivos golden (nesta pasta)
- `theme_list.cfg` — estado final desejado de `misc/theme_list.cfg`
- `theme_coverflow.cfg` — estado final desejado de `misc/theme_coverflow.cfg`

Estes são o resultado FINAL (upstream + customs) que o ELF deve embutir. Os binários
`gfx/` e os outros patches (`common.c` cores, etc.) são tratados em separado.

## Valores canônicos (o que costuma derivar — `theme_list.cfg`, modo lista)
| Elemento | Valor correto |
|---|---|
| ItemsList (lista de jogos) | x=20, y=57, width=400, height=342 |
| ItemCover (capa/box) | x=-61, y=-271 (overlay lm_case, coords padrão) |
| appsMain ItemCover | x=-61, y=-199 (overlay lm_apps_case) |
| ItemIcon (ícone da mídia / disc) | x=-245, y=-195, wsX=-210, 128x128, reflection=0 |
| MenuIcon | x=-11, y=348, aligned=2 |
| BdmIndex | x=-150, y=375, wsX=-115 |
| LoadingIcon | y=-80, 32x32 |
| ItemText (ID do jogo) | x=-94, y=-130 (main + appsMain) |
| **SEM** `lm_case_shadow` | a build antiga não tem sombra atrás da capa |

`theme_coverflow.cfg` (modo coverflow): ItemsList POS_MID/45, plank y=315, Coverflow
y=197 reflection=0, appsCoverflow y=239, MenuIcon x=-1 y=334. (Não costuma derivar.)

Cores (em `src/common.c` via patch, NÃO no theme cfg desde a migração libconfig):
bg=#000000, text=#FFFFFF, sel=#0079F5, ui_text=#B0B300, plasma_blend=#000000.

## Como restaurar se derivar de novo
1. Garanta o working tree limpo no upstream:
   `cd <repo> && git checkout HEAD -- misc/theme_list.cfg misc/theme_coverflow.cfg`
2. Copie os golden por cima:
   `cp reference/theme_list.cfg <repo>/misc/theme_list.cfg`
   `cp reference/theme_coverflow.cfg <repo>/misc/theme_coverflow.cfg`
3. Regenere os patches a partir do upstream:
   `git diff HEAD -- misc/theme_list.cfg     > "<...>/to build wOPL/patches/theme_list.cfg.patch"`
   `git diff HEAD -- misc/theme_coverflow.cfg > "<...>/to build wOPL/patches/theme_coverflow.cfg.patch"`
4. Rebuild.

Se o upstream mudar a estrutura dos cfgs (novos elementos/renumeração), faça merge manual
mantendo os VALORES da tabela acima e re-salve estes golden.

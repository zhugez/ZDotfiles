@{
    Packages = @(
        @{ Command = 'git.exe';       Winget = 'Git.Git';                    Scoop = 'git' }
        @{ Command = 'pwsh.exe';      Winget = 'Microsoft.PowerShell';       Scoop = 'pwsh' }
        @{ Command = 'wt.exe';        Winget = 'Microsoft.WindowsTerminal';  Scoop = 'extras/windows-terminal' }
        @{ Command = 'gh.exe';        Winget = 'GitHub.cli';                  Scoop = 'gh' }
        @{ Command = 'node.exe';      Winget = 'OpenJS.NodeJS.LTS';           Scoop = 'nodejs-lts' }
        @{ Command = 'bun.exe';       Winget = 'Oven-sh.Bun';                 Scoop = 'bun' }
        @{ Command = 'pnpm';          Winget = 'pnpm.pnpm';                   Scoop = 'pnpm' }
        @{ Command = 'go.exe';        Winget = 'GoLang.Go';                   Scoop = 'go' }
        @{ Command = 'python.exe';    Winget = 'Python.Python.3.14';          Scoop = 'python' }
        @{ Command = 'uv.exe';        Winget = 'astral-sh.uv';                Scoop = 'uv' }
        @{ Command = 'rustup.exe';    Winget = 'Rustlang.Rustup';             Scoop = 'rustup' }
        @{ Command = 'nvim.exe';      Winget = 'Neovim.Neovim';              Scoop = 'neovim' }
        @{ Command = 'oh-my-posh.exe'; Winget = 'JanDeDobbeleer.OhMyPosh';     Scoop = 'oh-my-posh' }
        @{ Command = 'zoxide.exe';    Winget = 'ajeetdsouza.zoxide';           Scoop = 'zoxide' }
        @{ Command = 'fzf.exe';       Winget = 'junegunn.fzf';                Scoop = 'fzf' }
        @{ Command = 'rg.exe';        Winget = 'BurntSushi.ripgrep.MSVC';      Scoop = 'ripgrep' }
        @{ Command = 'fd.exe';        Winget = 'sharkdp.fd';                  Scoop = 'fd' }
        @{ Command = 'bat.exe';       Winget = 'sharkdp.bat';                 Scoop = 'bat' }
        @{ Command = 'jq.exe';        Winget = 'jqlang.jq';                   Scoop = 'jq' }
        @{ Command = '7z.exe';        Winget = '7zip.7zip';                   Scoop = '7zip' }
        @{ Command = 'ffmpeg.exe';    Winget = 'Gyan.FFmpeg';                 Scoop = 'ffmpeg' }
        @{ Command = 'pdftoppm.exe';  Winget = 'oschwartz10612.Poppler';      Scoop = 'poppler' }
        @{ Command = 'magick.exe';    Winget = 'ImageMagick.ImageMagick';      Scoop = 'imagemagick' }
        @{ Command = 'yazi.exe';      Winget = 'sxyazi.yazi';                 Scoop = 'yazi' }
    )
    Modules = @('Terminal-Icons', 'PSFzf', 'posh-git')
}

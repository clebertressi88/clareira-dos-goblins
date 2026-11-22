using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ClareiraAtualizador;

internal sealed class Settings
{
    public string Folder { get; set; } = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "Clareira-dos-Goblins");
    public string Branch { get; set; } = "feature/paisagem-montanhas-rios-regeneracao";
    public bool Auto { get; set; } = true;
}

internal record Result(int Code, string Text)
{
    public bool Ok => Code == 0;
}

internal sealed class App : Form
{
    const string Repo = "clebertressi88/clareira-dos-goblins";
    const string Remote = "https://github.com/" + Repo + ".git";
    const string Feature = "feature/paisagem-montanhas-rios-regeneracao";
    static readonly string Config = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "ClareiraDosGoblins", "atualizador.json");
    readonly TextBox folder = new();
    readonly ComboBox branch = new();
    readonly CheckBox auto = new();
    readonly RichTextBox log = new();
    readonly Label status = new();
    readonly Button update = new();
    readonly Button updateGame = new();
    readonly System.Windows.Forms.Timer timer = new() { Interval = 600000 };
    bool busy;

    public App()
    {
        Text = "Clareira dos Goblins - Atualizador";
        ClientSize = new Size(900, 580);
        MinimumSize = new Size(800, 550);
        StartPosition = FormStartPosition.CenterScreen;
        Font = new Font("Segoe UI", 10);
        BackColor = Color.FromArgb(27, 36, 29);
        ForeColor = Color.White;
        var heading = new Label { Text = "CLAREIRA DOS GOBLINS", Font = new Font("Segoe UI Semibold", 21, FontStyle.Bold), ForeColor = Color.FromArgb(221, 197, 135) };
        heading.SetBounds(24, 18, 750, 50); Controls.Add(heading);
        Label("Atualize a mesma pasta. Alterações locais podem ser substituídas após backup confirmado.", 24, 67, 840);
        Label("PASTA LOCAL DO PROJETO", 24, 112, 500);
        folder.SetBounds(24, 140, 690, 33); folder.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right; Controls.Add(folder);
        var browse = Button("Escolher", 726, 140, 140, 33); browse.Anchor = AnchorStyles.Top | AnchorStyles.Right;
        browse.Click += (_, _) => { using var d = new FolderBrowserDialog { ShowNewFolderButton = true }; if (Directory.Exists(folder.Text)) d.SelectedPath = folder.Text; if (d.ShowDialog(this) == DialogResult.OK) { folder.Text = d.SelectedPath; Save(); } };
        Label("VERSÃO", 24, 195, 160);
        branch.DropDownStyle = ComboBoxStyle.DropDownList; branch.Items.AddRange(new object[] { "main", Feature });
        branch.SetBounds(24, 220, 600, 32); Controls.Add(branch);
        branch.SelectedIndexChanged += (_, _) => Save();
        auto.Text = "Baixar atualizações a cada 10 minutos enquanto este aplicativo estiver aberto";
        auto.SetBounds(24, 274, 820, 30); auto.CheckedChanged += (_, _) => Save(); Controls.Add(auto);
        update.Text = "ATUALIZAR CÓDIGO"; update.SetBounds(24, 324, 190, 43);
        update.FlatStyle = FlatStyle.Flat; update.BackColor = Color.FromArgb(65, 88, 63); update.ForeColor = Color.White;
        update.Click += async (_, _) => await Update(false); Controls.Add(update);
        updateGame.Text = "ATUALIZAR JOGO (EXE)"; updateGame.SetBounds(223, 324, 230, 43);
        updateGame.FlatStyle = FlatStyle.Flat; updateGame.BackColor = Color.FromArgb(85, 116, 65); updateGame.ForeColor = Color.White;
        updateGame.Click += async (_, _) => await UpdateGameExe(false); Controls.Add(updateGame);
        var auth = Button("Conectar GitHub", 462, 324, 145, 43);
        auth.Click += (_, _) => { try { Process.Start(new ProcessStartInfo("cmd.exe", "/k gh auth login --web --hostname github.com && gh auth setup-git") { UseShellExecute = true }); Log("Conclua o login na janela aberta e clique em atualizar."); } catch (Exception ex) { Alert(ex.Message); } };
        var open = Button("Abrir pasta", 615, 324, 120, 43);
        open.Click += (_, _) => { if (Directory.Exists(folder.Text)) Process.Start(new ProcessStartInfo("explorer.exe", "\"" + folder.Text + "\"") { UseShellExecute = true }); else Alert("A pasta ainda não existe."); };
        var github = Button("Ver GitHub", 743, 324, 120, 43);
        github.Click += (_, _) => Process.Start(new ProcessStartInfo("https://github.com/" + Repo) { UseShellExecute = true });
        status.SetBounds(24, 381, 850, 28); status.Text = "Pronto para atualizar"; status.ForeColor = Color.FromArgb(209, 215, 185); Controls.Add(status);
        log.ReadOnly = true; log.BackColor = Color.FromArgb(15, 23, 18); log.ForeColor = Color.FromArgb(222, 231, 213);
        log.Font = new Font("Consolas", 9); log.SetBounds(24, 414, 840, 125);
        log.Anchor = AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Top | AnchorStyles.Bottom; Controls.Add(log);
        LoadConfig(); FormClosing += (_, _) => Save();
        timer.Tick += async (_, _) => { if (auto.Checked && !busy) await Update(true); }; timer.Start();
        Shown += async (_, _) => { Log("O repositório é privado. Use Conectar GitHub no primeiro acesso."); if (auto.Checked && Directory.Exists(folder.Text) && Directory.EnumerateFileSystemEntries(folder.Text).Any()) await Update(true); };
    }

    void Label(string text, int x, int y, int width)
    {
        var l = new Label { Text = text }; l.SetBounds(x, y, width, 28); Controls.Add(l);
    }

    Button Button(string text, int x, int y, int width, int height)
    {
        var b = new Button { Text = text, BackColor = Color.FromArgb(50, 65, 51), ForeColor = Color.White, FlatStyle = FlatStyle.Flat };
        b.SetBounds(x, y, width, height); Controls.Add(b); return b;
    }

    void Log(string message) { log.AppendText("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + message + Environment.NewLine); log.ScrollToCaret(); }
    void Alert(string message) { status.Text = "Atenção: atualização interrompida"; status.ForeColor = Color.Salmon; Log(message); MessageBox.Show(this, message, "Atualizador - Atenção", MessageBoxButtons.OK, MessageBoxIcon.Warning); }

    void LoadConfig()
    {
        Settings s = new();
        // No pacote completo, a pasta Codigo-Fonte ja e um clone Git pronto para receber updates.
        try
        {
            var packaged = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "Codigo-Fonte"));
            if (Directory.Exists(Path.Combine(packaged, ".git")) && File.Exists(Path.Combine(packaged, "Projeto-Godot", "project.godot")))
                s.Folder = packaged;
        }
        catch { /* Usa pasta padrao se estiver fora do pacote. */ }
        try { if (File.Exists(Config)) s = JsonSerializer.Deserialize<Settings>(File.ReadAllText(Config)) ?? s; }
        catch { /* Preferências danificadas: inicia com valores seguros. */ }
        folder.Text = s.Folder; branch.SelectedItem = s.Branch is "main" or Feature ? s.Branch : Feature;
        if (branch.SelectedIndex < 0) branch.SelectedIndex = 1;
        auto.Checked = s.Auto;
    }

    void Save()
    {
        if (branch.SelectedItem == null) return;
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(Config)!);
            File.WriteAllText(Config, JsonSerializer.Serialize(new Settings { Folder = folder.Text.Trim(), Branch = branch.SelectedItem.ToString()!, Auto = auto.Checked }));
        }
        catch { Log("Não foi possível salvar as preferências."); }
    }

    async Task Update(bool automatic)
    {
        if (busy) return;
        var path = folder.Text.Trim();
        var selected = branch.SelectedItem?.ToString() ?? "main";
        if (path.Length == 0 || !Regex.IsMatch(selected, @"^[a-zA-Z0-9][a-zA-Z0-9._/-]*$") || selected.Contains("..")) { if (!automatic) Alert("Pasta ou versão inválida."); return; }
        try { path = Path.GetFullPath(path); } catch { if (!automatic) Alert("Pasta inválida."); return; }
        busy = true; update.Enabled = false; status.Text = "Verificando GitHub...";
        Save();
        try
        {
            Log("Verificando versão: " + selected);
            if (!(await Run("git", "--version")).Ok) throw new Exception("Instale o Git: https://git-scm.com/download/win");
            if (!(await Run("gh", "--version")).Ok) throw new Exception("Instale o GitHub CLI: https://cli.github.com/");
            if (!(await Run("gh", "auth", "status", "-h", "github.com")).Ok) throw new Exception("Clique em Conectar GitHub para autenticar sua conta.");
            if (!(await Run("gh", "auth", "setup-git")).Ok) throw new Exception("Não foi possível configurar a autenticação do Git.");
            if (!Directory.Exists(path)) Directory.CreateDirectory(path);
            var root = await Git(path, "rev-parse", "--show-toplevel");
            if (!root.Ok)
            {
                if (Directory.EnumerateFileSystemEntries(path).Any())
                {
                    // Pastas antigas (sem .git) podem ser migradas SEM APAGAR a instalação.
                    // O original é renomeado para backup ao lado da pasta de destino.
                    if (automatic)
                    {
                        status.Text = "Pasta antiga: confirme a instalação por cima";
                        Log("Pasta existente sem Git. Abra o atualizador e clique em Atualizar para autorizar o backup.");
                        return;
                    }
                    if (!File.Exists(Path.Combine(path, "Projeto-Godot", "project.godot")) &&
                        !File.Exists(Path.Combine(path, "project.godot")))
                        throw new Exception("A pasta não parece ser o jogo Clareira dos Goblins. Escolha uma pasta do jogo ou uma pasta vazia.");
                    if (!ConfirmOverwrite("A pasta selecionada não contém um repositório Git.\\n\\n" +
                        "Deseja INSTALAR A NOVA VERSÃO NA MESMA PASTA?\\n" +
                        "A pasta antiga será guardada INTEIRA ao lado, como backup.\\n" +
                        "O aplicativo não apagará o projeto antigo.\\n\\nFeche o Godot antes de continuar."))
                        return;
                    await InstallOverLegacy(path, selected);
                    return;
                }
                Log("Baixando o projeto na pasta escolhida...");
                var clone = await Run("git", "clone", "--branch", selected, Remote, path);
                if (!clone.Ok) throw new Exception("Falha no primeiro download: " + Short(clone.Text));
                Log("Download concluído! Abra Projeto-Godot/project.godot no Godot.");
                status.Text = "Projeto baixado com sucesso";
                return;
            }
            var selectedPath = Path.GetFullPath(path).TrimEnd(Path.DirectorySeparatorChar);
            path = Path.GetFullPath(root.Text.Trim().Split('\n', '\r')[0]).TrimEnd(Path.DirectorySeparatorChar);
            if (!string.Equals(path, selectedPath, StringComparison.OrdinalIgnoreCase))
                throw new Exception("Escolha a pasta raiz do jogo (Codigo-Fonte), não Projeto-Godot ou uma subpasta.");
            var remote = await Git(path, "remote", "get-url", "origin");
            var valid = Regex.IsMatch(remote.Text.Trim(), @"^(https://github\.com/|git@github\.com:|ssh://git@github\.com/)clebertressi88/clareira-dos-goblins(\.git)?/?$", RegexOptions.IgnoreCase);
            if (!remote.Ok || !valid) throw new Exception("Esta pasta pertence a outro repositório. Nenhum arquivo foi modificado.");
            var dirty = await Git(path, "status", "--porcelain=v1");
            if (!dirty.Ok) throw new Exception("Não foi possível conferir alterações locais.");
            var changes = dirty.Text.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
            // O Godot 4.7 regenera arquivos .import e .gd.uid automaticamente na primeira abertura.
            // Faz backup dos metadados regenerados e restaura APENAS os .import versionados,
            // sem tocar em cenas, scripts, texturas ou configuracoes alteradas pelo usuario.
            bool generatedOnly = changes.All(line =>
                line.Length > 3 &&
                line[3..].Replace('\\', '/').StartsWith("Projeto-Godot/", StringComparison.OrdinalIgnoreCase) &&
                (line.EndsWith(".import", StringComparison.OrdinalIgnoreCase) ||
                 (line.StartsWith("?? ") && line.EndsWith(".gd.uid", StringComparison.OrdinalIgnoreCase))));
            if (changes.Length > 0 && !generatedOnly)
            {
                if (automatic)
                {
                    status.Text = "Existem alterações locais. Atualização manual necessária.";
                    Log("Atualização automática interrompida para preservar edições. Clique em Atualizar para fazer backup e instalar por cima.");
                    return;
                }
                if (!ConfirmOverwrite("Há arquivos modificados no projeto local.\\n\\n" +
                    "Deseja SUBSTITUÍ-LOS pela versão do GitHub?\\n" +
                    "Antes disso, criarei um ZIP com o PROJETO INTEIRO em uma pasta de backup.\\n" +
                    "Suas alterações permanecerão dentro desse ZIP.\\n\\nFeche o Godot antes de continuar."))
                    return;
                await ReplaceGitWithBackup(path, selected);
                return;
            }
            var imported = changes.Where(line => !line.StartsWith("?? ") && line.EndsWith(".import", StringComparison.OrdinalIgnoreCase))
                                  .Select(line => line[3..].Replace('\\', '/')).ToArray();
            if (imported.Length > 0)
            {
                var backupDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "ClareiraDosGoblins", "backups-importacao", DateTime.Now.ToString("yyyyMMdd-HHmmss-fff"));
                foreach (var relative in imported)
                {
                    var original = Path.GetFullPath(Path.Combine(path, relative.Replace('/', Path.DirectorySeparatorChar)));
                    if (!original.StartsWith(path.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
                        throw new Exception("Caminho de importação inválido.");
                    var backup = Path.Combine(backupDir, relative.Replace('/', Path.DirectorySeparatorChar));
                    Directory.CreateDirectory(Path.GetDirectoryName(backup)!);
                    File.Copy(original, backup, overwrite: false);
                }
                var restoreArgs = new[] { "restore", "--worktree", "--" }.Concat(imported).ToArray();
                if (!(await Git(path, restoreArgs)).Ok) throw new Exception("Não foi possível restaurar arquivos .import. Backup preservado em " + backupDir);
                Log("Metadados gerados pelo Godot copiados para: " + backupDir);
            }
            Log("Baixando mudanças do GitHub...");
            var fetch = await Git(path, "fetch", "--prune", "origin");
            if (!fetch.Ok) throw new Exception("Falha na conexão com GitHub: " + Short(fetch.Text));
            if (!(await Git(path, "show-ref", "--verify", "--quiet", "refs/remotes/origin/" + selected)).Ok) throw new Exception("Versão não encontrada no GitHub.");
            bool exists = (await Git(path, "show-ref", "--verify", "--quiet", "refs/heads/" + selected)).Ok;
            var checkout = exists ? await Git(path, "checkout", selected) : await Git(path, "checkout", "-b", selected, "--track", "origin/" + selected);
            if (!checkout.Ok)
            {
                if (!automatic && ConfirmOverwrite("Não foi possível trocar de versão sem conflitos.\\n\\n" +
                    "Deseja criar um BACKUP completo e instalar por cima da pasta atual?"))
                {
                    await ReplaceGitWithBackup(path, selected);
                    return;
                }
                throw new Exception("Não foi possível trocar de versão: " + Short(checkout.Text));
            }
            var before = await Git(path, "rev-parse", "--short", "HEAD");
            if (!(await Git(path, "merge-base", "--is-ancestor", "HEAD", "origin/" + selected)).Ok)
            {
                if (!automatic && ConfirmOverwrite("Esta pasta tem commits locais divergentes.\\n\\n" +
                    "Deseja fazer BACKUP integral e substituir pelo conteúdo do GitHub?"))
                {
                    await ReplaceGitWithBackup(path, selected);
                    return;
                }
                throw new Exception("Há commits locais divergentes. Clique em Atualizar e confirme o backup para instalar por cima.");
            }
            var merge = await Git(path, "merge", "--ff-only", "origin/" + selected);
            if (!merge.Ok)
            {
                if (!automatic && ConfirmOverwrite("A atualização não pôde ser aplicada sem conflitos.\\n\\n" +
                    "Deseja fazer BACKUP integral e instalar por cima?"))
                {
                    await ReplaceGitWithBackup(path, selected);
                    return;
                }
                throw new Exception("Git recusou a atualização: " + Short(merge.Text));
            }
            var after = await Git(path, "rev-parse", "--short", "HEAD");
            status.Text = before.Text.Trim() == after.Text.Trim() ? "O projeto já está atualizado" : "Atualização concluída";
            status.ForeColor = Color.LightGreen;
            Log(status.Text + " — commit " + after.Text.Trim());
        }
        catch (Exception ex)
        {
            if (automatic) { Log("Verificação automática não concluída: " + ex.Message); status.Text = "Atualização requer atenção"; status.ForeColor = Color.Salmon; }
            else Alert(ex.Message);
        }
        finally { busy = false; update.Enabled = true; updateGame.Enabled = true; }
    }

    async Task UpdateGameExe(bool automatic)
    {
        if (busy) return;
        var selected = branch.SelectedItem?.ToString() ?? Feature;
        if (selected != Feature)
        {
            if (!automatic) Alert("O EXE compilado está disponível na versão experimental da paisagem. Selecione essa versão.");
            return;
        }

        var sourceFolder = folder.Text.Trim();
        string target = "";
        try
        {
            // Layout oficial: Codigo-Fonte/ e Jogo-Windows/ sao pastas irmas.
            var root = Path.GetFullPath(sourceFolder);
            var baseFolder = Directory.GetParent(root)?.FullName ?? "";
            if (!string.IsNullOrWhiteSpace(baseFolder))
                target = Path.Combine(baseFolder, "Jogo-Windows", "Clareira-dos-Goblins.exe");

            if (string.IsNullOrWhiteSpace(target) || !File.Exists(target))
            {
                if (automatic) return;
                using var picker = new OpenFileDialog
                {
                    Title = "Selecione o EXE atual na pasta Jogo-Windows",
                    Filter = "Jogo Clareira dos Goblins|Clareira-dos-Goblins.exe",
                    CheckFileExists = true,
                    FileName = "Clareira-dos-Goblins.exe"
                };
                if (picker.ShowDialog(this) != DialogResult.OK) return;
                target = picker.FileName;
            }
            target = Path.GetFullPath(target);
            if (!string.Equals(Path.GetFileName(target), "Clareira-dos-Goblins.exe", StringComparison.OrdinalIgnoreCase))
                throw new Exception("Selecione o executável correto do jogo.");
        }
        catch (Exception ex) { if (!automatic) Alert("Local do jogo inválido: " + ex.Message); return; }

        busy = true;
        update.Enabled = false;
        updateGame.Enabled = false;
        status.Text = "Consultando versão compilada do jogo...";
        var temporary = "";
        try
        {
            if (Process.GetProcessesByName("Clareira-dos-Goblins").Length > 0)
                throw new Exception("Feche o jogo antes de atualizar o executável.");
            if (!(await Run("gh", "--version")).Ok)
                throw new Exception("Instale GitHub CLI: https://cli.github.com");
            if (!(await Run("gh", "auth", "status", "-h", "github.com")).Ok)
                throw new Exception("Clique em Conectar GitHub para acessar o repositório privado.");

            // Somente arquivos produzidos pela workflow oficial de compilacao desta branch.
            var head = await Run("gh", "api",
                "repos/" + Repo + "/git/ref/heads/" + selected, "--jq", ".object.sha");
            if (!head.Ok || !Regex.IsMatch(head.Text.Trim(), "^[0-9a-fA-F]{40}$"))
                throw new Exception("Não foi possível confirmar o commit atual no GitHub.");

            var list = await Run("gh", "run", "list", "-R", Repo,
                "--workflow", "compilar-correcao-wasd.yml",
                "--branch", selected, "--status", "success",
                "--json", "databaseId,headSha", "--limit", "30");
            if (!list.Ok) throw new Exception("Não foi possível consultar as compilações do jogo: " + Short(list.Text));

            long runId = 0;
            using (var document = JsonDocument.Parse(list.Text))
            {
                foreach (var item in document.RootElement.EnumerateArray())
                {
                    if (item.TryGetProperty("headSha", out var sha) &&
                        string.Equals(sha.GetString(), head.Text.Trim(), StringComparison.OrdinalIgnoreCase) &&
                        item.TryGetProperty("databaseId", out var id))
                    {
                        runId = id.GetInt64();
                        break;
                    }
                }
            }
            if (runId == 0)
                throw new Exception("Ainda não existe EXE aprovado para o último commit do jogo. Consulte GitHub Actions → Compilar correcao controles WASD Windows.");

            var marker = Path.Combine(Path.GetDirectoryName(target)!, ".clareira-exe-versao.txt");
            if (File.Exists(marker))
            {
                var values = File.ReadAllLines(marker);
                if (values.Length >= 3 && values[0] == runId.ToString() &&
                    values[1].Equals(head.Text.Trim(), StringComparison.OrdinalIgnoreCase) &&
                    values[2].Equals(HashFile(target), StringComparison.OrdinalIgnoreCase))
                {
                    status.Text = "O executável do jogo já está atualizado";
                    status.ForeColor = Color.LightGreen;
                    Log("O EXE instalado corresponde à compilação " + runId);
                    return;
                }
            }

            Log("Baixando executável da compilação validada #" + runId + "...");
            temporary = Path.Combine(Path.GetTempPath(), "Clareira-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(temporary);
            var result = await Run("gh", "run", "download", runId.ToString(), "-R", Repo,
                "--name", "Clareira-Correcao-WASD-Windows",
                "--dir", temporary);
            if (!result.Ok) throw new Exception("Falha ao baixar o executável: " + Short(result.Text));
            var downloaded = Path.Combine(temporary, "Clareira-dos-Goblins.exe");
            if (!File.Exists(downloaded)) throw new Exception("O arquivo EXE não veio no pacote do GitHub.");
            using (var stream = File.OpenRead(downloaded))
            {
                if (stream.Length < 1000000 || stream.ReadByte() != 0x4D || stream.ReadByte() != 0x5A)
                    throw new Exception("Executável baixado inválido. Nenhum arquivo foi substituído.");
            }

            // Copia em staging na mesma unidade e troca atomicamente (com backup).
            var destFolder = Path.GetDirectoryName(target)!;
            Directory.CreateDirectory(destFolder);
            var staging = Path.Combine(destFolder, ".Clareira-Nova-" + Guid.NewGuid().ToString("N") + ".exe");
            var backup = target + ".backup-" + DateTime.Now.ToString("yyyyMMdd-HHmmss");
            File.Copy(downloaded, staging);
            try
            {
                if (Process.GetProcessesByName("Clareira-dos-Goblins").Length > 0)
                    throw new Exception("O jogo foi aberto durante o download. Feche-o e tente novamente.");
                if (File.Exists(target))
                    File.Replace(staging, target, backup, true);
                else
                    File.Move(staging, target);
            }
            finally
            {
                if (File.Exists(staging)) File.Delete(staging);
            }
            File.WriteAllLines(marker, new[] { runId.ToString(), head.Text.Trim(), HashFile(target) });
            status.Text = "Jogo (EXE) atualizado com sucesso";
            status.ForeColor = Color.LightGreen;
            Log(status.Text + " — compilação #" + runId);
            if (File.Exists(backup)) Log("Backup do executável anterior: " + backup);
            if (!automatic)
                MessageBox.Show(this, "Jogo atualizado na mesma pasta. Abra JOGAR.cmd para testar.",
                    "Clareira dos Goblins", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            if (automatic) { Log("EXE ainda não atualizado: " + ex.Message); status.Text = "Atualização do EXE requer atenção"; }
            else Alert(ex.Message);
        }
        finally
        {
            if (!string.IsNullOrWhiteSpace(temporary))
                try { if (Directory.Exists(temporary)) Directory.Delete(temporary, true); } catch { }
            busy = false; update.Enabled = true; updateGame.Enabled = true;
        }
    }

    static string HashFile(string path)
    {
        using var stream = File.OpenRead(path);
        return Convert.ToHexString(SHA256.HashData(stream));
    }

    bool ConfirmOverwrite(string message)
    {
        return MessageBox.Show(this, message.Replace("\\n", Environment.NewLine),
            "Atualizar na mesma pasta (backup obrigatório)",
            MessageBoxButtons.YesNo, MessageBoxIcon.Warning,
            MessageBoxDefaultButton.Button2) == DialogResult.Yes;
    }

    async Task<string> BackupProject(string path)
    {
        var parent = Directory.GetParent(path)?.FullName
            ?? throw new Exception("A pasta raiz do disco não pode ser substituída.");
        var name = Path.GetFileName(path.TrimEnd(Path.DirectorySeparatorChar));
        if (string.IsNullOrWhiteSpace(name)) throw new Exception("Pasta do projeto inválida.");
        string archivePath = Path.Combine(parent, name + "-BACKUP-" +
            DateTime.Now.ToString("yyyyMMdd-HHmmss-fff") + ".zip");
        if (archivePath.StartsWith(path.TrimEnd(Path.DirectorySeparatorChar) +
            Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
            throw new Exception("O backup não pode ficar dentro da pasta que será atualizada.");
        Log("Criando backup completo antes de substituir qualquer arquivo...");
        status.Text = "Criando backup do projeto...";
        await Task.Run(() =>
        {
            try
            {
                ZipFile.CreateFromDirectory(path, archivePath, CompressionLevel.Fastest, true);
                using var archive = ZipFile.OpenRead(archivePath);
                if (archive.Entries.Count == 0 || new FileInfo(archivePath).Length == 0)
                    throw new Exception("Arquivo de backup vazio.");
            }
            catch
            {
                try { if (File.Exists(archivePath)) File.Delete(archivePath); } catch { }
                throw;
            }
        });
        Log("Backup confirmado: " + archivePath);
        return archivePath;
    }

    async Task ReplaceGitWithBackup(string path, string selected)
    {
        // Backup integral inclusive de arquivos nao rastreados. Nunca apague o backup.
        string archive = await BackupProject(path);
        Log("Buscando arquivos da versão " + selected + "...");
        var fetch = await Git(path, "fetch", "--prune", "origin");
        if (!fetch.Ok) throw new Exception("Falhou o download. Sua pasta não foi substituída. Backup: " + archive + "\n" + Short(fetch.Text));
        if (!(await Git(path, "show-ref", "--verify", "--quiet", "refs/remotes/origin/" + selected)).Ok)
            throw new Exception("Versão indisponível. Pasta original preservada. Backup: " + archive);
        // Substituicao intencional somente apos confirmacao e backup verificado.
        var checkout = await Git(path, "checkout", "-f", "-B", selected, "origin/" + selected);
        if (!checkout.Ok) throw new Exception("Falhou a troca da versão. O backup está em: " + archive + "\n" + Short(checkout.Text));
        var reset = await Git(path, "reset", "--hard", "origin/" + selected);
        if (!reset.Ok) throw new Exception("Não foi possível finalizar a instalação. Backup: " + archive + "\n" + Short(reset.Text));
        var clean = await Git(path, "clean", "-fd");
        if (!clean.Ok) throw new Exception("Versão atualizada, mas sobram arquivos antigos. Backup: " + archive + "\n" + Short(clean.Text));
        status.Text = "Instalado por cima — backup criado";
        status.ForeColor = Color.LightGreen;
        Log("Atualizado na MESMA pasta: " + path);
        Log("Versão anterior salva em: " + archive);
        MessageBox.Show(this, "Atualização concluída na mesma pasta!\n\nBackup da versão anterior:\n" +
            archive, "Clareira dos Goblins", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    async Task InstallOverLegacy(string path, string selected)
    {
        string parent = Directory.GetParent(path)?.FullName
            ?? throw new Exception("Não é permitido substituir a raiz do disco.");
        string name = Path.GetFileName(path.TrimEnd(Path.DirectorySeparatorChar));
        var stamp = DateTime.Now.ToString("yyyyMMdd-HHmmss-fff");
        string staging = Path.Combine(parent, name + "-NOVA-VERSAO-" + stamp);
        string backup = Path.Combine(parent, name + "-BACKUP-" + stamp);
        Log("Baixando uma cópia limpa antes de mexer na pasta existente...");
        var clone = await Run("git", "clone", "--branch", selected, "--", Remote, staging);
        if (!clone.Ok)
            throw new Exception("Falha ao baixar projeto novo. A pasta original permanece intacta.\n" + Short(clone.Text));
        // A instalacao antiga continua INTEIRA, somente com novo nome. Nao precisa copiar/deletar.
        try
        {
            Directory.Move(path, backup);
            try { Directory.Move(staging, path); }
            catch
            {
                // Melhor esforco para devolver o nome original.
                try { if (!Directory.Exists(path)) Directory.Move(backup, path); } catch { }
                throw;
            }
        }
        catch (Exception ex)
        {
            throw new Exception("Não foi possível substituir a pasta (feche o Godot e o jogo). " +
                "Pasta antiga ou backup preservado: " + backup + ". Detalhes: " + ex.Message);
        }
        status.Text = "Instalado na pasta anterior, com backup";
        status.ForeColor = Color.LightGreen;
        Log("Instalação nova: " + path);
        Log("Pasta antiga INTEIRA preservada em: " + backup);
        MessageBox.Show(this, "Instalado na mesma pasta!\n\n" +
            "Sua instalação antiga continua salva em:\n" + backup,
            "Clareira dos Goblins", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    static string Short(string s) => s.Length > 260 ? s[..260] : s;
    static Task<Result> Git(string folder, params string[] args) => Run("git", (new[] { "-C", folder }).Concat(args).ToArray());

    static async Task<Result> Run(string exe, params string[] args)
    {
        using var p = new Process();
        p.StartInfo = new ProcessStartInfo(exe)
        {
            UseShellExecute = false, CreateNoWindow = true,
            RedirectStandardOutput = true, RedirectStandardError = true
        };
        foreach (var arg in args) p.StartInfo.ArgumentList.Add(arg);
        if (exe == "git") p.StartInfo.Environment["GIT_TERMINAL_PROMPT"] = "0";
        try { p.Start(); }
        catch (System.ComponentModel.Win32Exception) { return new Result(127, exe + " não está instalado."); }
        using var timeout = new CancellationTokenSource(TimeSpan.FromMinutes(4));
        var stdout = p.StandardOutput.ReadToEndAsync(); var stderr = p.StandardError.ReadToEndAsync();
        try { await p.WaitForExitAsync(timeout.Token); await Task.WhenAll(stdout, stderr); }
        catch (OperationCanceledException)
        {
            try { p.Kill(entireProcessTree: true); } catch { }
            throw new Exception("Tempo de atualização excedido. Tente novamente.");
        }
        return new Result(p.ExitCode, (await stdout) + (await stderr));
    }
}

internal static class Program
{
    [STAThread] static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new App());
    }
}

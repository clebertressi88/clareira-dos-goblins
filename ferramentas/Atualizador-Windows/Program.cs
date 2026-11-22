using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
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
        Label("Atualização segura do projeto Godot pelo repositório privado no GitHub.", 24, 67, 840);
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
        update.Text = "BAIXAR / ATUALIZAR AGORA"; update.SetBounds(24, 324, 290, 43);
        update.FlatStyle = FlatStyle.Flat; update.BackColor = Color.FromArgb(85, 116, 65); update.ForeColor = Color.White;
        update.Click += async (_, _) => await Update(false); Controls.Add(update);
        var auth = Button("Conectar GitHub", 326, 324, 166, 43);
        auth.Click += (_, _) => { try { Process.Start(new ProcessStartInfo("cmd.exe", "/k gh auth login --web --hostname github.com && gh auth setup-git") { UseShellExecute = true }); Log("Conclua o login na janela aberta e clique em atualizar."); } catch (Exception ex) { Alert(ex.Message); } };
        var open = Button("Abrir pasta", 504, 324, 144, 43);
        open.Click += (_, _) => { if (Directory.Exists(folder.Text)) Process.Start(new ProcessStartInfo("explorer.exe", "\"" + folder.Text + "\"") { UseShellExecute = true }); else Alert("A pasta ainda não existe."); };
        var github = Button("Ver GitHub", 660, 324, 144, 43);
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
                    throw new Exception("Esta pasta contém arquivos mas não é um clone Git. Para proteger o projeto existente, selecione uma pasta VAZIA. Nada foi sobrescrito.");
                Log("Baixando o projeto na pasta escolhida...");
                var clone = await Run("git", "clone", "--branch", selected, Remote, path);
                if (!clone.Ok) throw new Exception("Falha no primeiro download: " + Short(clone.Text));
                Log("Download concluído! Abra Projeto-Godot/project.godot no Godot.");
                status.Text = "Projeto baixado com sucesso";
                return;
            }
            path = Path.GetFullPath(root.Text.Trim().Split('\n', '\r')[0]);
            var remote = await Git(path, "remote", "get-url", "origin");
            var valid = Regex.IsMatch(remote.Text.Trim(), @"^(https://github\.com/|git@github\.com:|ssh://git@github\.com/)clebertressi88/clareira-dos-goblins(\.git)?/?$", RegexOptions.IgnoreCase);
            if (!remote.Ok || !valid) throw new Exception("Esta pasta pertence a outro repositório. Nenhum arquivo foi modificado.");
            var dirty = await Git(path, "status", "--porcelain=v1");
            if (!dirty.Ok || !string.IsNullOrWhiteSpace(dirty.Text)) throw new Exception("Há modificações locais. Faça commit ou backup e resolva as alterações antes de atualizar. Nada foi sobrescrito.");
            Log("Baixando mudanças do GitHub...");
            var fetch = await Git(path, "fetch", "--prune", "origin");
            if (!fetch.Ok) throw new Exception("Falha na conexão com GitHub: " + Short(fetch.Text));
            if (!(await Git(path, "show-ref", "--verify", "--quiet", "refs/remotes/origin/" + selected)).Ok) throw new Exception("Versão não encontrada no GitHub.");
            bool exists = (await Git(path, "show-ref", "--verify", "--quiet", "refs/heads/" + selected)).Ok;
            var checkout = exists ? await Git(path, "checkout", selected) : await Git(path, "checkout", "-b", selected, "--track", "origin/" + selected);
            if (!checkout.Ok) throw new Exception("Não foi possível trocar de versão: " + Short(checkout.Text));
            var before = await Git(path, "rev-parse", "--short", "HEAD");
            if (!(await Git(path, "merge-base", "--is-ancestor", "HEAD", "origin/" + selected)).Ok)
                throw new Exception("Há commits locais divergentes. Atualização bloqueada para não perder trabalho.");
            var merge = await Git(path, "merge", "--ff-only", "origin/" + selected);
            if (!merge.Ok) throw new Exception("Git recusou a atualização: " + Short(merge.Text));
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
        finally { busy = false; update.Enabled = true; }
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

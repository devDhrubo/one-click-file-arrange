using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Data;
using System.Text.RegularExpressions;
using System.Web.Script.Serialization;
using System.Reflection;

[assembly: AssemblyTitle("Desktop & Folder File Organizer")]
[assembly: AssemblyDescription("Organize Desktop and folders into categorized subfolders with 1 click.")]
[assembly: AssemblyCompany("Dolan Dhrubo Ray")]
[assembly: AssemblyProduct("Desktop File Organizer")]
[assembly: AssemblyCopyright("Copyright © 2026 Dolan Dhrubo Ray")]
[assembly: AssemblyFileVersion("1.0.0.0")]
[assembly: AssemblyVersion("1.0.0.0")]

namespace FileOrganizer
{
    public class FileMoveItem
    {
        public string OriginalFile { get; set; }
        public string OriginalPath { get; set; }
        public string Category { get; set; }
        public string Destination { get; set; }
        public string FormattedSize { get; set; }
        public long Size { get; set; }
    }

    public class HistoryMove
    {
        public string OriginalPath { get; set; }
        public string NewPath { get; set; }
        public string Category { get; set; }
        public string FileName { get; set; }
    }

    public class Transaction
    {
        public string Timestamp { get; set; }
        public string TargetDir { get; set; }
        public int MovedCount { get; set; }
        public List<string> FoldersCreated { get; set; }
        public List<HistoryMove> Moves { get; set; }
    }

    public class HistoryData
    {
        public List<Transaction> Transactions { get; set; }
    }

    public class MainWindow : Window
    {
        private TextBox txtDirectory;
        private ListView lvFiles;
        private TextBlock lblStatus;
        private TextBlock lblSubStatus;
        private TextBlock badgeScreenshots, badgeDocs, badgeImages, badgeVideos, badgeAudio, badgeOthers;
        private Button btnOrganize, btnUndo;
        private string currentDesktopPath;

        private static readonly Dictionary<string, HashSet<string>> CategoryExtensions = new Dictionary<string, HashSet<string>>(StringComparer.OrdinalIgnoreCase)
        {
            { "PDFs & Documents", new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".pdf", ".docx", ".doc", ".txt", ".rtf", ".odt", ".xlsx", ".xls", ".csv", ".pptx", ".ppt", ".epub", ".pages", ".numbers", ".key", ".tsv", ".md", ".xopp" } },
            { "Images & Photos", new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp", ".ico", ".tiff", ".tif", ".raw", ".heic", ".psd", ".ai", ".eps", ".avif" } },
            { "Videos", new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".mp4", ".mkv", ".mov", ".avi", ".wmv", ".flv", ".webm", ".m4v", ".3gp", ".ts", ".vob", ".mpg", ".mpeg" } },
            { "Audio & Music", new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".mp3", ".wav", ".aac", ".flac", ".ogg", ".m4a", ".wma", ".opus", ".mid", ".midi" } },
            { "Archives & Compressed", new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".xz", ".tgz", ".iso", ".cab", ".dmg" } },
            { "Installers & Executables", new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".exe", ".msi", ".msix", ".appx", ".reg" } },
            { "Code & Development", new HashSet<string>(StringComparer.OrdinalIgnoreCase) { ".py", ".js", ".jsx", ".ts", ".tsx", ".html", ".htm", ".css", ".scss", ".json", ".xml", ".yaml", ".yml", ".sql", ".cpp", ".c", ".h", ".cs", ".java", ".go", ".rs", ".php", ".rb", ".sh", ".ps1", ".bat" } }
        };

        private static readonly HashSet<string> ExcludedFiles = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "desktop.ini", "thumbs.db", ".ds_store", ".organizer_history.json",
            "fileorganizer.exe", "file_organizer.bat", "launch_organizer_gui.bat", "organize_desktop_now.bat"
        };

        private static readonly HashSet<string> ExcludedExtensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            ".lnk", ".url"
        };

        public MainWindow()
        {
            Title = "⚡ Desktop & Folder File Organizer";
            Width = 880;
            Height = 680;
            WindowStartupLocation = WindowStartupLocation.CenterScreen;
            Background = new SolidColorBrush(Color.FromRgb(15, 23, 42)); // Slate 900
            Foreground = new SolidColorBrush(Color.FromRgb(248, 250, 252));
            FontFamily = new FontFamily("Segoe UI, Arial");

            currentDesktopPath = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);

            BuildUI();
            RefreshFileList();
        }

        private void BuildUI()
        {
            var mainGrid = new Grid { Margin = new Thickness(20) };
            mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // 0: Header
            mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // 1: Path Selector
            mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // 2: Category Badges
            mainGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) }); // 3: Table
            mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // 4: Actions

            // 1. Header
            var headerBorder = new Border
            {
                Padding = new Thickness(0, 0, 0, 12),
                BorderThickness = new Thickness(0, 0, 0, 1),
                BorderBrush = new SolidColorBrush(Color.FromRgb(30, 41, 59)),
                Margin = new Thickness(0, 0, 0, 14)
            };
            var headerGrid = new Grid();
            headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            var headerStack = new StackPanel();
            var titleText = new TextBlock
            {
                Text = "⚡ Desktop & Folder File Organizer",
                FontSize = 22,
                FontWeight = FontWeights.Bold,
                Foreground = Brushes.White
            };
            var subTitleText = new TextBlock
            {
                Text = "Sort screenshots, documents, PDFs, videos, and images safely into clean folders with 1 click.",
                FontSize = 12,
                Foreground = new SolidColorBrush(Color.FromRgb(148, 163, 184)),
                Margin = new Thickness(0, 4, 0, 0)
            };
            headerStack.Children.Add(titleText);
            headerStack.Children.Add(subTitleText);
            Grid.SetColumn(headerStack, 0);
            headerGrid.Children.Add(headerStack);

            var devBadge = new Border
            {
                Background = new SolidColorBrush(Color.FromRgb(30, 41, 59)),
                BorderBrush = new SolidColorBrush(Color.FromRgb(59, 130, 246)),
                BorderThickness = new Thickness(1),
                CornerRadius = new CornerRadius(8),
                Padding = new Thickness(12, 6, 12, 6),
                VerticalAlignment = VerticalAlignment.Center
            };
            var devStack = new StackPanel { Orientation = Orientation.Horizontal };
            var devIcon = new TextBlock { Text = "👨‍💻 ", FontSize = 12, VerticalAlignment = VerticalAlignment.Center };
            var devText = new TextBlock
            {
                Text = "Developer: Dolan Dhrubo Ray",
                FontSize = 12,
                FontWeight = FontWeights.SemiBold,
                Foreground = new SolidColorBrush(Color.FromRgb(147, 197, 253)),
                VerticalAlignment = VerticalAlignment.Center
            };
            devStack.Children.Add(devIcon);
            devStack.Children.Add(devText);
            devBadge.Child = devStack;
            Grid.SetColumn(devBadge, 1);
            headerGrid.Children.Add(devBadge);

            headerBorder.Child = headerGrid;
            Grid.SetRow(headerBorder, 0);
            mainGrid.Children.Add(headerBorder);

            // 2. Folder Selector Card
            var folderCard = new Border
            {
                Background = new SolidColorBrush(Color.FromRgb(30, 41, 59)),
                CornerRadius = new CornerRadius(10),
                Padding = new Thickness(14),
                BorderThickness = new Thickness(1),
                BorderBrush = new SolidColorBrush(Color.FromRgb(51, 65, 85)),
                Margin = new Thickness(0, 0, 0, 12)
            };
            var folderGrid = new Grid();
            folderGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            folderGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

            var lblSelect = new TextBlock
            {
                Text = "Target Folder Location:",
                FontWeight = FontWeights.SemiBold,
                Foreground = new SolidColorBrush(Color.FromRgb(203, 213, 225)),
                Margin = new Thickness(0, 0, 0, 8)
            };
            folderGrid.Children.Add(lblSelect);

            var inputRow = new Grid();
            inputRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            inputRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            inputRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            inputRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            txtDirectory = new TextBox
            {
                Text = currentDesktopPath,
                Background = new SolidColorBrush(Color.FromRgb(15, 23, 42)),
                Foreground = Brushes.White,
                BorderBrush = new SolidColorBrush(Color.FromRgb(71, 85, 105)),
                Padding = new Thickness(10, 8, 10, 8),
                FontSize = 13,
                VerticalContentAlignment = VerticalAlignment.Center,
                Margin = new Thickness(0, 0, 8, 0)
            };
            Grid.SetColumn(txtDirectory, 0);
            inputRow.Children.Add(txtDirectory);

            var btnBrowse = CreateButton("📁 Browse...", Color.FromRgb(51, 65, 85));
            btnBrowse.Margin = new Thickness(0, 0, 6, 0);
            btnBrowse.Click += (s, e) =>
            {
                var dialog = new System.Windows.Forms.FolderBrowserDialog { SelectedPath = txtDirectory.Text };
                if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                {
                    txtDirectory.Text = dialog.SelectedPath;
                    RefreshFileList();
                }
            };
            Grid.SetColumn(btnBrowse, 1);
            inputRow.Children.Add(btnBrowse);

            var btnDesktop = CreateButton("🖥️ Desktop", Color.FromRgb(51, 65, 85));
            btnDesktop.Margin = new Thickness(0, 0, 6, 0);
            btnDesktop.Click += (s, e) =>
            {
                txtDirectory.Text = currentDesktopPath;
                RefreshFileList();
            };
            Grid.SetColumn(btnDesktop, 2);
            inputRow.Children.Add(btnDesktop);

            var btnRefresh = CreateButton("🔄 Scan", Color.FromRgb(59, 130, 246));
            btnRefresh.Click += (s, e) => RefreshFileList();
            Grid.SetColumn(btnRefresh, 3);
            inputRow.Children.Add(btnRefresh);

            Grid.SetRow(inputRow, 1);
            folderGrid.Children.Add(inputRow);
            folderCard.Child = folderGrid;
            Grid.SetRow(folderCard, 1);
            mainGrid.Children.Add(folderCard);

            // 3. Category Badges Card
            var badgeCard = new Border
            {
                Background = new SolidColorBrush(Color.FromRgb(30, 41, 59)),
                CornerRadius = new CornerRadius(10),
                Padding = new Thickness(12, 10, 12, 10),
                BorderThickness = new Thickness(1),
                BorderBrush = new SolidColorBrush(Color.FromRgb(51, 65, 85)),
                Margin = new Thickness(0, 0, 0, 12)
            };
            var badgePanel = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                HorizontalAlignment = HorizontalAlignment.Center
            };

            badgeScreenshots = CreateBadge("📸 Screenshots: 0", Color.FromRgb(3, 105, 161), badgePanel);
            badgeDocs = CreateBadge("📄 Docs & PDFs: 0", Color.FromRgb(180, 83, 9), badgePanel);
            badgeImages = CreateBadge("🖼️ Images: 0", Color.FromRgb(4, 120, 87), badgePanel);
            badgeVideos = CreateBadge("🎥 Videos: 0", Color.FromRgb(109, 40, 217), badgePanel);
            badgeAudio = CreateBadge("🎵 Audio: 0", Color.FromRgb(190, 24, 93), badgePanel);
            badgeOthers = CreateBadge("📦 Others: 0", Color.FromRgb(71, 85, 105), badgePanel);

            badgeCard.Child = badgePanel;
            Grid.SetRow(badgeCard, 2);
            mainGrid.Children.Add(badgeCard);

            // 4. File Table View
            lvFiles = new ListView
            {
                Background = new SolidColorBrush(Color.FromRgb(30, 41, 59)),
                Foreground = Brushes.White,
                BorderBrush = new SolidColorBrush(Color.FromRgb(51, 65, 85)),
                Margin = new Thickness(0, 0, 0, 12)
            };
            var gridView = new GridView();
            gridView.Columns.Add(new GridViewColumn { Header = "File Name", Width = 280, DisplayMemberBinding = new Binding("OriginalFile") });
            gridView.Columns.Add(new GridViewColumn { Header = "Target Category Folder", Width = 180, DisplayMemberBinding = new Binding("Category") });
            gridView.Columns.Add(new GridViewColumn { Header = "Size", Width = 90, DisplayMemberBinding = new Binding("FormattedSize") });
            gridView.Columns.Add(new GridViewColumn { Header = "Destination Path", Width = 240, DisplayMemberBinding = new Binding("Destination") });
            lvFiles.View = gridView;
            Grid.SetRow(lvFiles, 3);
            mainGrid.Children.Add(lvFiles);

            // 5. Action Footer
            var footerCard = new Border
            {
                Background = new SolidColorBrush(Color.FromRgb(30, 41, 59)),
                CornerRadius = new CornerRadius(10),
                Padding = new Thickness(14),
                BorderThickness = new Thickness(1),
                BorderBrush = new SolidColorBrush(Color.FromRgb(51, 65, 85))
            };
            var footerGrid = new Grid();
            footerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            footerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            footerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            var statusStack = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
            lblStatus = new TextBlock
            {
                Text = "Ready to organize files.",
                Foreground = new SolidColorBrush(Color.FromRgb(56, 189, 248)),
                FontWeight = FontWeights.SemiBold,
                FontSize = 13
            };
            lblSubStatus = new TextBlock
            {
                Text = "Desktop shortcuts (.lnk) and system files are safely preserved.",
                Foreground = new SolidColorBrush(Color.FromRgb(100, 116, 139)),
                FontSize = 11,
                Margin = new Thickness(0, 2, 0, 0)
            };
            statusStack.Children.Add(lblStatus);
            statusStack.Children.Add(lblSubStatus);
            footerGrid.Children.Add(statusStack);

            btnUndo = CreateButton("↩️ Undo Last Move", Color.FromRgb(239, 68, 68));
            btnUndo.Margin = new Thickness(0, 0, 10, 0);
            btnUndo.Click += (s, e) => PerformUndo();
            Grid.SetColumn(btnUndo, 1);
            footerGrid.Children.Add(btnUndo);

            btnOrganize = CreateButton("⚡ Organize Now", Color.FromRgb(16, 185, 129));
            btnOrganize.FontSize = 14;
            btnOrganize.FontWeight = FontWeights.Bold;
            btnOrganize.Padding = new Thickness(22, 10, 22, 10);
            btnOrganize.Click += (s, e) => PerformOrganize();
            Grid.SetColumn(btnOrganize, 2);
            footerGrid.Children.Add(btnOrganize);

            footerCard.Child = footerGrid;
            Grid.SetRow(footerCard, 4);
            mainGrid.Children.Add(footerCard);

            Content = mainGrid;
        }

        private Button CreateButton(string text, Color bgColor)
        {
            var btn = new Button
            {
                Content = text,
                Background = new SolidColorBrush(bgColor),
                Foreground = Brushes.White,
                FontWeight = FontWeights.SemiBold,
                FontSize = 13,
                Padding = new Thickness(14, 8, 14, 8),
                BorderThickness = new Thickness(0),
                Cursor = System.Windows.Input.Cursors.Hand
            };
            var template = new ControlTemplate(typeof(Button));
            var borderFactory = new FrameworkElementFactory(typeof(Border));
            borderFactory.SetValue(Border.CornerRadiusProperty, new CornerRadius(8));
            borderFactory.SetValue(Border.BackgroundProperty, new TemplateBindingExtension(Button.BackgroundProperty));
            borderFactory.SetValue(Border.PaddingProperty, new TemplateBindingExtension(Button.PaddingProperty));
            var contentFactory = new FrameworkElementFactory(typeof(ContentPresenter));
            contentFactory.SetValue(ContentPresenter.HorizontalAlignmentProperty, HorizontalAlignment.Center);
            contentFactory.SetValue(ContentPresenter.VerticalAlignmentProperty, VerticalAlignment.Center);
            borderFactory.AppendChild(contentFactory);
            template.VisualTree = borderFactory;
            btn.Template = template;
            return btn;
        }

        private TextBlock CreateBadge(string text, Color bgColor, StackPanel parent)
        {
            var b = new Border
            {
                Background = new SolidColorBrush(bgColor),
                CornerRadius = new CornerRadius(6),
                Padding = new Thickness(10, 4, 10, 4),
                Margin = new Thickness(4, 0, 4, 0)
            };
            var tb = new TextBlock
            {
                Text = text,
                FontWeight = FontWeights.SemiBold,
                Foreground = Brushes.White,
                FontSize = 12
            };
            b.Child = tb;
            parent.Children.Add(b);
            return tb;
        }

        private string GetCategory(string fileName, string ext)
        {
            string nameLower = fileName.ToLower();
            string extLower = ext.ToLower();

            // Check screenshot pattern
            if (extLower == ".png" || extLower == ".jpg" || extLower == ".jpeg" || extLower == ".bmp" || extLower == ".webp")
            {
                if (nameLower.Contains("screenshot") || nameLower.Contains("screen shot") || nameLower.Contains("snip") || nameLower.Contains("capture"))
                {
                    return "Screenshots";
                }
            }

            foreach (var kvp in CategoryExtensions)
            {
                if (kvp.Value.Contains(extLower))
                {
                    return kvp.Key;
                }
            }

            return "Others";
        }

        private string GetUniquePath(string targetFolder, string originalName)
        {
            string dest = Path.Combine(targetFolder, originalName);
            if (!File.Exists(dest)) return dest;

            string baseName = Path.GetFileNameWithoutExtension(originalName);
            string ext = Path.GetExtension(originalName);
            int counter = 1;
            while (File.Exists(dest))
            {
                dest = Path.Combine(targetFolder, string.Format("{0} ({1}){2}", baseName, counter, ext));
                counter++;
            }
            return dest;
        }

        private string FormatBytes(long bytes)
        {
            if (bytes >= 1024 * 1024 * 1024) return string.Format("{0:0.00} GB", (double)bytes / (1024 * 1024 * 1024));
            if (bytes >= 1024 * 1024) return string.Format("{0:0.00} MB", (double)bytes / (1024 * 1024));
            if (bytes >= 1024) return string.Format("{0:0.00} KB", (double)bytes / 1024);
            return bytes + " B";
        }

        private string GetHistoryFilePath(string dir)
        {
            string appData = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "FileOrganizer");
            Directory.CreateDirectory(appData);
            string hash = Convert.ToBase64String(Encoding.UTF8.GetBytes(dir.ToLower())).Replace('/', '_').Replace('+', '-').TrimEnd('=');
            return Path.Combine(appData, "history_" + hash + ".json");
        }

        private void RefreshFileList()
        {
            string dir = txtDirectory.Text.Trim();
            if (!Directory.Exists(dir))
            {
                lblStatus.Text = "Folder does not exist: " + dir;
                lblStatus.Foreground = Brushes.IndianRed;
                lvFiles.ItemsSource = null;
                return;
            }

            lblStatus.Text = "Scanning folder...";
            lblStatus.Foreground = Brushes.DeepSkyBlue;

            var items = new List<FileMoveItem>();
            int cScr = 0, cDocs = 0, cImg = 0, cVid = 0, cAud = 0, cOth = 0;

            try
            {
                var files = Directory.GetFiles(dir);
                foreach (var file in files)
                {
                    string fName = Path.GetFileName(file);
                    string ext = Path.GetExtension(file);

                    if (ExcludedFiles.Contains(fName) || ExcludedExtensions.Contains(ext)) continue;

                    string cat = GetCategory(fName, ext);
                    string dest = GetUniquePath(Path.Combine(dir, cat), fName);
                    var fi = new FileInfo(file);

                    switch (cat)
                    {
                        case "Screenshots": cScr++; break;
                        case "PDFs & Documents": cDocs++; break;
                        case "Images & Photos": cImg++; break;
                        case "Videos": cVid++; break;
                        case "Audio & Music": cAud++; break;
                        default: cOth++; break;
                    }

                    items.Add(new FileMoveItem
                    {
                        OriginalFile = fName,
                        OriginalPath = file,
                        Category = cat,
                        Destination = Path.GetFileName(dest),
                        FormattedSize = FormatBytes(fi.Length),
                        Size = fi.Length
                    });
                }

                lvFiles.ItemsSource = items;
                badgeScreenshots.Text = "📸 Screenshots: " + cScr;
                badgeDocs.Text = "📄 Docs & PDFs: " + cDocs;
                badgeImages.Text = "🖼️ Images: " + cImg;
                badgeVideos.Text = "🎥 Videos: " + cVid;
                badgeAudio.Text = "🎵 Audio: " + cAud;
                badgeOthers.Text = "📦 Others: " + cOth;

                if (items.Count == 0)
                {
                    lblStatus.Text = "✨ All clean! No loose files to organize in this folder.";
                    lblStatus.Foreground = Brushes.MediumSpringGreen;
                    lblSubStatus.Text = "Everything is already inside subfolders.";
                }
                else
                {
                    lblStatus.Text = "Found " + items.Count + " files ready to be organized.";
                    lblStatus.Foreground = Brushes.LightSkyBlue;
                    lblSubStatus.Text = "Click '⚡ Organize Now' to sort them into folders safely.";
                }
            }
            catch (Exception ex)
            {
                lblStatus.Text = "Error: " + ex.Message;
                lblStatus.Foreground = Brushes.IndianRed;
            }
        }

        private void PerformOrganize()
        {
            string dir = txtDirectory.Text.Trim();
            if (!Directory.Exists(dir)) return;

            var items = lvFiles.ItemsSource as List<FileMoveItem>;
            if (items == null || items.Count == 0)
            {
                MessageBox.Show("No unorganized files found in this folder.", "Notice", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            var moves = new List<HistoryMove>();
            var createdFolders = new List<string>();

            foreach (var item in items)
            {
                string targetFolder = Path.Combine(dir, item.Category);
                if (!Directory.Exists(targetFolder))
                {
                    Directory.CreateDirectory(targetFolder);
                    if (!createdFolders.Contains(targetFolder)) createdFolders.Add(targetFolder);
                }

                string finalDest = GetUniquePath(targetFolder, item.OriginalFile);
                try
                {
                    File.Move(item.OriginalPath, finalDest);
                    moves.Add(new HistoryMove
                    {
                        OriginalPath = item.OriginalPath,
                        NewPath = finalDest,
                        Category = item.Category,
                        FileName = item.OriginalFile
                    });
                }
                catch { }
            }

            // Save history
            try
            {
                string histPath = GetHistoryFilePath(dir);
                var js = new JavaScriptSerializer();
                HistoryData histData = new HistoryData { Transactions = new List<Transaction>() };
                if (File.Exists(histPath))
                {
                    try { histData = js.Deserialize<HistoryData>(File.ReadAllText(histPath, Encoding.UTF8)); } catch { }
                }
                if (histData.Transactions == null) histData.Transactions = new List<Transaction>();

                histData.Transactions.Add(new Transaction
                {
                    Timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                    TargetDir = dir,
                    MovedCount = moves.Count,
                    FoldersCreated = createdFolders,
                    Moves = moves
                });

                File.WriteAllText(histPath, js.Serialize(histData), Encoding.UTF8);
            }
            catch { }

            RefreshFileList();
            MessageBox.Show(string.Format("Successfully organized {0} files into categorized folders!", moves.Count), "Organization Complete", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        private void PerformUndo()
        {
            string dir = txtDirectory.Text.Trim();
            string histPath = GetHistoryFilePath(dir);

            if (!File.Exists(histPath))
            {
                MessageBox.Show("No undo history found for this folder.", "Undo Notice", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            var confirm = MessageBox.Show("Do you want to undo the last file organization in this folder?", "Confirm Undo", MessageBoxButton.YesNo, MessageBoxImage.Question);
            if (confirm != MessageBoxResult.Yes) return;

            try
            {
                var js = new JavaScriptSerializer();
                var histData = js.Deserialize<HistoryData>(File.ReadAllText(histPath, Encoding.UTF8));
                if (histData.Transactions == null || histData.Transactions.Count == 0)
                {
                    MessageBox.Show("No actions to undo.", "Undo Notice", MessageBoxButton.OK, MessageBoxImage.Information);
                    return;
                }

                var lastTx = histData.Transactions[histData.Transactions.Count - 1];
                int restored = 0;

                foreach (var move in lastTx.Moves)
                {
                    if (File.Exists(move.NewPath))
                    {
                        try
                        {
                            File.Move(move.NewPath, move.OriginalPath);
                            restored++;
                        }
                        catch { }
                    }
                }

                if (lastTx.FoldersCreated != null)
                {
                    foreach (var folder in lastTx.FoldersCreated)
                    {
                        if (Directory.Exists(folder) && Directory.GetFileSystemEntries(folder).Length == 0)
                        {
                            try { Directory.Delete(folder); } catch { }
                        }
                    }
                }

                histData.Transactions.RemoveAt(histData.Transactions.Count - 1);
                if (histData.Transactions.Count > 0)
                {
                    File.WriteAllText(histPath, js.Serialize(histData), Encoding.UTF8);
                }
                else
                {
                    File.Delete(histPath);
                }

                RefreshFileList();
                MessageBox.Show(string.Format("Restored {0} files back to their original positions.", restored), "Undo Complete", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to undo: " + ex.Message, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }

    public static class Program
    {
        [STAThread]
        public static void Main()
        {
            try
            {
                var app = new Application();
                var window = new MainWindow();
                window.Show();
                app.Run(window);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error Starting File Organizer", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }
}

# Desktop & Folder File Organizer - Modern GUI (WPF)

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$EngineScript = Join-Path -Path $ScriptDirectory -ChildPath "organizer.ps1"

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Desktop and Folder File Organizer"
    Height="680" Width="860"
    WindowStartupLocation="CenterScreen"
    Background="#0F172A"
    FontFamily="Segoe UI, Arial"
    Foreground="#F8FAFC">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#3B82F6"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="8"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SecondaryButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#334155"/>
            <Setter Property="Foreground" Value="#E2E8F0"/>
        </Style>

        <Style x:Key="SuccessButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#10B981"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>

        <Style x:Key="UndoButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#EF4444"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#1E293B"/>
            <Setter Property="Foreground" Value="#F1F5F9"/>
            <Setter Property="BorderBrush" Value="#475569"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <Style TargetType="ListView">
            <Setter Property="Background" Value="#1E293B"/>
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="BorderBrush" Value="#334155"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>

        <Style TargetType="GridViewColumnHeader">
            <Setter Property="Background" Value="#0F172A"/>
            <Setter Property="Foreground" Value="#94A3B8"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="BorderThickness" Value="0,0,0,1"/>
            <Setter Property="BorderBrush" Value="#334155"/>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- 1. Header Banner -->
        <Border Grid.Row="0" Margin="0,0,0,16" Padding="0,0,0,8" BorderBrush="#1E293B" BorderThickness="0,0,0,1">
            <StackPanel Orientation="Vertical">
                <TextBlock Text="Desktop and Folder Organizer" FontSize="22" FontWeight="Bold" Foreground="#FFFFFF"/>
                <TextBlock Text="Sort screenshots, documents, PDFs, videos, and images safely into clean folders with 1 click." 
                           Foreground="#94A3B8" FontSize="12" Margin="0,4,0,0"/>
            </StackPanel>
        </Border>

        <!-- 2. Target Directory Card -->
        <Border Grid.Row="1" Background="#1E293B" CornerRadius="10" Padding="14" Margin="0,0,0,14" BorderBrush="#334155" BorderThickness="1">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                
                <TextBlock Grid.Row="0" Text="Select Target Location:" FontWeight="SemiBold" Foreground="#CBD5E1" Margin="0,0,0,8"/>
                
                <Grid Grid.Row="1">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <TextBox Name="txtDirectory" Grid.Column="0" Margin="0,0,8,0"/>
                    <Button Name="btnBrowse" Grid.Column="1" Content="Browse..." Style="{StaticResource SecondaryButton}" Margin="0,0,6,0"/>
                    <Button Name="btnDesktop" Grid.Column="2" Content="Desktop" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0"/>
                    <Button Name="btnRefresh" Grid.Column="3" Content="Scan" Style="{StaticResource SecondaryButton}"/>
                </Grid>
            </Grid>
        </Border>

        <!-- 3. Category Summary Badge Panel -->
        <Border Grid.Row="2" Background="#1E293B" CornerRadius="10" Padding="12,10" Margin="0,0,0,12" BorderBrush="#334155" BorderThickness="1">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <Border Background="#0369A1" CornerRadius="6" Padding="10,4" Margin="4,0">
                    <TextBlock Name="badgeScreenshots" Text="Screenshots: 0" FontWeight="SemiBold" Foreground="#E0F2FE" FontSize="12"/>
                </Border>
                <Border Background="#B45309" CornerRadius="6" Padding="10,4" Margin="4,0">
                    <TextBlock Name="badgeDocs" Text="Docs and PDFs: 0" FontWeight="SemiBold" Foreground="#FEF3C7" FontSize="12"/>
                </Border>
                <Border Background="#047857" CornerRadius="6" Padding="10,4" Margin="4,0">
                    <TextBlock Name="badgeImages" Text="Images: 0" FontWeight="SemiBold" Foreground="#D1FAE5" FontSize="12"/>
                </Border>
                <Border Background="#6D28D9" CornerRadius="6" Padding="10,4" Margin="4,0">
                    <TextBlock Name="badgeVideos" Text="Videos: 0" FontWeight="SemiBold" Foreground="#EDE9FE" FontSize="12"/>
                </Border>
                <Border Background="#BE185D" CornerRadius="6" Padding="10,4" Margin="4,0">
                    <TextBlock Name="badgeAudio" Text="Audio: 0" FontWeight="SemiBold" Foreground="#FCE7F3" FontSize="12"/>
                </Border>
                <Border Background="#475569" CornerRadius="6" Padding="10,4" Margin="4,0">
                    <TextBlock Name="badgeOthers" Text="Others: 0" FontWeight="SemiBold" Foreground="#F1F5F9" FontSize="12"/>
                </Border>
            </StackPanel>
        </Border>

        <!-- 4. Files Preview List -->
        <Grid Grid.Row="3" Margin="0,0,0,14">
            <ListView Name="lvFiles">
                <ListView.View>
                    <GridView>
                        <GridViewColumn Header="File Name" Width="280" DisplayMemberBinding="{Binding OriginalFile}"/>
                        <GridViewColumn Header="Target Category Folder" Width="180" DisplayMemberBinding="{Binding Category}"/>
                        <GridViewColumn Header="Size" Width="90" DisplayMemberBinding="{Binding FormattedSize}"/>
                        <GridViewColumn Header="Destination Preview" Width="240" DisplayMemberBinding="{Binding Destination}"/>
                    </GridView>
                </ListView.View>
            </ListView>
        </Grid>

        <!-- 5. Action and Status Footer Bar -->
        <Border Grid.Row="4" Background="#1E293B" CornerRadius="10" Padding="14" BorderBrush="#334155" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" VerticalAlignment="Center">
                    <TextBlock Name="lblStatus" Text="Ready to scan and organize files." Foreground="#38BDF8" FontWeight="SemiBold" FontSize="13"/>
                    <TextBlock Name="lblSubStatus" Text="Desktop shortcuts (.lnk) and system files are safely preserved." Foreground="#64748B" FontSize="11" Margin="0,2,0,0"/>
                </StackPanel>

                <Button Name="btnUndo" Grid.Column="1" Content="Undo Last Move" Style="{StaticResource UndoButton}" Margin="0,0,10,0" Padding="16,10"/>
                <Button Name="btnOrganize" Grid.Column="2" Content="Organize Now" Style="{StaticResource SuccessButton}" Padding="20,10"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Element references
$txtDirectory = $window.FindName("txtDirectory")
$btnBrowse = $window.FindName("btnBrowse")
$btnDesktop = $window.FindName("btnDesktop")
$btnRefresh = $window.FindName("btnRefresh")
$lvFiles = $window.FindName("lvFiles")
$lblStatus = $window.FindName("lblStatus")
$lblSubStatus = $window.FindName("lblSubStatus")
$btnOrganize = $window.FindName("btnOrganize")
$btnUndo = $window.FindName("btnUndo")

$badgeScreenshots = $window.FindName("badgeScreenshots")
$badgeDocs = $window.FindName("badgeDocs")
$badgeImages = $window.FindName("badgeImages")
$badgeVideos = $window.FindName("badgeVideos")
$badgeAudio = $window.FindName("badgeAudio")
$badgeOthers = $window.FindName("badgeOthers")

$desktopPath = [Environment]::GetFolderPath("Desktop")
$txtDirectory.Text = $desktopPath

function Format-FileSize {
    param ([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Refresh-FileList {
    $target = $txtDirectory.Text.Trim()
    if (-not (Test-Path -LiteralPath $target)) {
        $lblStatus.Text = "Folder path not found: $target"
        $lblStatus.Foreground = [System.Windows.Media.Brushes]::IndianRed
        return
    }

    $lblStatus.Text = "Scanning folder..."
    $lblStatus.Foreground = [System.Windows.Media.Brushes]::DeepSkyBlue
    $lvFiles.ItemsSource = $null

    try {
        $previewData = & $EngineScript -TargetDirectory $target -Preview -Silent
        
        $viewItems = [System.Collections.ArrayList]::new()
        $cScreenshots = 0
        $cDocs = 0
        $cImages = 0
        $cVideos = 0
        $cAudio = 0
        $cOthers = 0

        if ($previewData) {
            foreach ($item in $previewData) {
                $cat = [string]$item.Category
                switch ($cat) {
                    "Screenshots" { $cScreenshots++ }
                    "PDFs & Documents" { $cDocs++ }
                    "Images & Photos" { $cImages++ }
                    "Videos" { $cVideos++ }
                    "Audio & Music" { $cAudio++ }
                    Default { $cOthers++ }
                }

                $null = $viewItems.Add([PSCustomObject]@{
                    OriginalFile  = $item.OriginalFile
                    OriginalPath  = $item.OriginalPath
                    Category      = $item.Category
                    Destination   = [System.IO.Path]::GetFileName($item.Destination)
                    FormattedSize = (Format-FileSize $item.Size)
                })
            }
        }

        $lvFiles.ItemsSource = $viewItems

        $badgeScreenshots.Text = "Screenshots: $cScreenshots"
        $badgeDocs.Text = "Docs and PDFs: $cDocs"
        $badgeImages.Text = "Images: $cImages"
        $badgeVideos.Text = "Videos: $cVideos"
        $badgeAudio.Text = "Audio: $cAudio"
        $badgeOthers.Text = "Others: $cOthers"

        if ($viewItems.Count -eq 0) {
            $lblStatus.Text = "All clean! No loose files to organize in this folder."
            $lblStatus.Foreground = [System.Windows.Media.Brushes]::MediumSpringGreen
            $lblSubStatus.Text = "Everything is organized or already inside subfolders."
        } else {
            $lblStatus.Text = "Found $($viewItems.Count) files ready to be organized."
            $lblStatus.Foreground = [System.Windows.Media.Brushes]::LightSkyBlue
            $lblSubStatus.Text = "Click 'Organize Now' to sort them into folders safely."
        }
    } catch {
        $lblStatus.Text = "Error during scan: $_"
        $lblStatus.Foreground = [System.Windows.Media.Brushes]::IndianRed
    }
}

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.SelectedPath = $txtDirectory.Text
    $dialog.Description = "Select Folder to Organize"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtDirectory.Text = $dialog.SelectedPath
        Refresh-FileList
    }
})

$btnDesktop.Add_Click({
    $txtDirectory.Text = $desktopPath
    Refresh-FileList
})

$btnRefresh.Add_Click({
    Refresh-FileList
})

$btnOrganize.Add_Click({
    $target = $txtDirectory.Text.Trim()
    if (-not (Test-Path -LiteralPath $target)) {
        [System.Windows.MessageBox]::Show("Please select a valid folder path.", "Invalid Folder", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $result = & $EngineScript -TargetDirectory $target -Silent
    if ($result.Success) {
        $lblStatus.Text = "$($result.Message)"
        $lblStatus.Foreground = [System.Windows.Media.Brushes]::MediumSpringGreen
        $lblSubStatus.Text = "Files sorted successfully. Click 'Undo Last Move' anytime to revert."
        Refresh-FileList
        [System.Windows.MessageBox]::Show("Successfully organized $($result.MovedCount) files into categorized folders!", "Organization Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } else {
        $lblStatus.Text = "Notice: $($result.Message)"
        $lblStatus.Foreground = [System.Windows.Media.Brushes]::IndianRed
    }
})

$btnUndo.Add_Click({
    $target = $txtDirectory.Text.Trim()
    $confirm = [System.Windows.MessageBox]::Show("Do you want to undo the last file organization in this folder?", "Confirm Undo", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
        $undoResult = & $EngineScript -TargetDirectory $target -Undo -Silent
        if ($undoResult.Success) {
            $lblStatus.Text = "$($undoResult.Message)"
            $lblStatus.Foreground = [System.Windows.Media.Brushes]::LightGreen
            $lblSubStatus.Text = "All files returned to original location."
            Refresh-FileList
            [System.Windows.MessageBox]::Show($undoResult.Message, "Undo Completed", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            [System.Windows.MessageBox]::Show($undoResult.Message, "Undo Notice", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        }
    }
})

$window.Add_Loaded({
    Refresh-FileList
})

$window.ShowDialog() | Out-Null

[![Join the chat at https://gitter.im/MaTeX-help/Lobby](https://badges.gitter.im/MaTeX-help/Lobby.svg)](https://gitter.im/MaTeX-help/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![GitHub (pre-)release](https://img.shields.io/github/release/szhorvat/MaTeX/all.svg)](https://github.com/szhorvat/MaTeX/releases)
[![Github All Releases](https://img.shields.io/github/downloads/szhorvat/MaTeX/total.svg)](https://github.com/szhorvat/MaTeX/releases)
[![Contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](https://github.com/szhorvat/MaTeX/issues)
[![DOI](https://zenodo.org/badge/31675019.svg)](https://zenodo.org/badge/latestdoi/31675019)

----

[English](README.md) | [中文](README.zh_cn.md)

----

# MaTeX

在 Mathematica 里使用 LaTeX 的输出效果

请参阅 [博客文章](http://szhorvat.net/pelican/latex-typesetting-in-mathematica.html)，以获取有关 MaTeX 的详细介绍和最新的故障排除信息。

## 安装

**在 Mathematica 11.3 或更高版本中，只需运行 `ResourceFunction["MaTeXInstall"][]` 即可安装或升级 MaTeX。**

在不支持资源功能的旧版本中，请遵循手动安装说明：

- [下载最新版本](https://github.com/szhorvat/MaTeX/releases)，以 `.paclet` 文件形式分发，并使用 Mathematica 中的 `PacletInstall` 函数进行安装。例如，假设文件 "MaTeX-1.7.7.paclet" 已下载到目录 `~/Downloads` 中，请执行

    ```mathematica
    Needs["PacletManager`"]
    PacletInstall["~/Downloads/MaTeX-1.7.7.paclet"]
    ```

    获取文件路径的最便捷方法是 Mathematica 的 插入→文件路径。.. 菜单命令。

- 确保已安装 [TeX 系统](https://tug.org/begin.html) 和 Ghostscript 9.15 或更高版本。

     对于 Windows 和 Linux，可从 [其官方下载页面](http://ghostscript.com/download/gsdnld.html) 获得最新的 Ghostscript。

     在 OS X 上，MacTeX 2015 和更高版本已包含兼容版本的 Ghostscript。如果您使用的不是较旧的 TeX 发行版，请从 [Richard Koch 的页面](http://pages.uoregon.edu/koch/) 获取最新的 Ghostscript。

- 运行 ``<<MaTeX` ``。首次加载时，MaTeX 会尝试自动进行自我配置。如果自动配置失败，它将显示有关如何手动配置 pdflatex 和 Ghostscript 可执行文件的路径的说明。 *注意：* 在 Windows 系统上，请使用命令行 Ghostscript 可执行文件，即名称以 c 结尾的文件：gswin32c.exe 或 gswin64c.exe。

- 用 `MaTeX ["x ^ 2"]` 测试 MaTeX。

    打开文档中心，搜索 "MaTeX" 以开始使用。

## 升级或卸载

当已经存在旧版本时，可以安全地安装新版本。 ``<<MaTeX` `` 将始终加载与您的 Mathematica 版本兼容的最新安装的 MaTeX。

可以使用以下命令检索所有已安装版本的列表

```mathematica
    PacletFind["MaTeX"]
```

可以通过运行 `PacletUninstall` 来卸载列表中的任何项目。要一次卸载所有版本，请使用

```mathematica
    PacletUninstall["MaTeX"]
```

要查看有关 `Needs` 加载的版本的更多信息，请使用

```mathematica
    PacletInformaton["MaTeX"]
```

**注意：** 如果您是在开始使用 paclet 分发格式（即 1.6.2 版）之前安装 MaTeX 的，请通过从以下位置删除 `MaTeX` 目录来卸载它。

```mathematica
    SystemOpen@FileNameJoin[{$UserBaseDirectory, "Applications"}]
```

----

以下函数将自动下载并安装最新版本的 MaTeX：

```mathematica
    updateMaTeX[] :=
      Module[{json, download, target},
        Check[
          json = Import["https://api.github.com/repos/szhorvat/MaTeX/releases/latest", "JSON"];
          download = Lookup[First@Lookup[json, "assets"], "browser_download_url"];
          target = FileNameJoin[{CreateDirectory[], "MaTeX.paclet"}];
          If[$Notebooks,
            PrintTemporary@Labeled[ProgressIndicator[Appearance -> "Necklace"], "Downloading...", Right],
            Print["Downloading..."]
          ];
          URLSave[download, target]
          ,
          Return[$Failed]
        ];
        If[FileExistsQ[target], PacletManager`PacletInstall[target], $Failed]
      ]
```

在运行了上面的函数定义之后，只需运行 `updateMaTeX[]`，然后运行 ``<<MaTeX` ``，以加载更新的版本。

## 用法

使用 `MaTeX [texcode]` 或 `MaTeX [expression]` 使用 LaTeX 进行排版。后者将自动将 `TeXForm` 应用于 `expression`。

LaTeX 代码以数学模式解释。在 Mathematica 字符串中编写 LaTeX 代码时，请记住要避免反斜杠（即当你想表示一个 `\` 时请输入 *两个* `\` 字符），例如

```Mathematica
    MaTeX["\\sum_{k=1}^{\\infty} \\frac{1}{k}"]
```

也可以一次性处理多个表达式：

```Mathematica
    MaTeX[{
      "\\frac{x^2}{\\sqrt{3}}",
      HoldForm[Integrate[Sin[x], {x, 0, 2 Pi}]],
      Expand[(1 + x)^5]
    }]
```

一起处理表达式列表仅需要运行一次 LaTeX ，因此比分别处理每个表达式要快得多。

有关更多用法说明，请在文档中心中搜索 "MaTeX"。

## 性能说明

`MaTeX` 调用速度的瓶颈是运行 `pdflatex` 进程，该过程可能需要一秒钟的时间，无法进一步加快。但是，MaTeX 会缓存结果，从而使得使用相同 TeX 代码的后续调用几乎是瞬时的。 MaTeX 还可以使用 LaTeX 一次性运行处理表达式列表，这比分别处理每个表达式要快得多。

## 修订记录

#### 版本 1.7.7

 - 修复了与 Ghostscript 9.53.1 的兼容性

#### 版本 1.7.6

 - 提高了与 Mathematica 12.0 和 12.1 的兼容性
 - 提高了可靠性

#### 版本 1.7.5

- 文档改进
- 改进了错误报告

#### 版本 1.7.4

- 文档改进

#### 版本 1.7.3

- 添加了 `"WorkingDirectory"` 配置选项。这使得用户可以解决 Windows 上某些 Mathematica 版本中的 `RunProcess` 错误，在名称中包含非 ASCII 字符的目录中，`RunProcess` 将报错。
- 公开了 ``MaTeX`Developer`Texify``，允许用户自定义表达式以进行 TeX 代码转换。请参阅 MaTeX 符号文档页面中的整洁示例。
- 文档改进

#### 版本 1.7.2

- 与 Mathematica 11.2 中的新文档搜索更好地兼容
- 当 Ghostscript 失败时，更好的错误报告
- 文档改进

#### 版本 1.7.1

- 解决一个罕见的 `RunProcess` 错误，该错误会影响 Linux 上的某些 Mathematica 10.0 安装
- 文档改进，以及一个与图形准备有关的新教程

#### 版本 1.7.0

- 内部重构，修复和完善较小的错误
- ``MaTeX`Developer` ``中有助于故障排除的新函数
- 漏洞修复：由于 Mathematica 更改了 `LD_LIBRARY_PATH`，在某些 Linux 发行版上运行 Ghostscript 或 pdflatex 会失败

#### 版本 1.6.3

- 更鲁棒的错误检查和报告
- 文档改进

#### 版本 1.6.2

- 现在，文档已集成到文档中心。
- 错误修复：恢复了与 Mathematica 10.0 的完全兼容性。

#### 版本 1.6.1

- 错误修复：对 CacheSize 配置选项进行更好的错误检查。

#### 版本 1.6.0

- `MaTeX`现在遍历列表。用 LaTeX 一次性批量处理列表，这比逐个处理元素要快得多。此功能由 [Andreas Ahlrichs](https://github.com/aquadr) 部署。

    请注意，这会稍微改变行为。MaTeX 的早期版本将`MaTeX [{1,x ^ 2,x / 2}]` 编译为单个表达式。现在，列表中的每个元素都将转换为单独的结果。要恢复以前版本的效果，请显式应用 `TeXForm` ：`MaTeX [TeXForm [{1,x ^ 2,x / 2}]`。

- 现在可以自动处理带有 `TeXForm` 头的表达式。

- 错误修复：更好地处理 CR / LF 行尾和字符编码。

#### 版本 1.5.0

- 大大改进了 LaTeX 错误报告。请使用新的错误报告功能报告您发现的任何问题。
- MaTeX 现在检查常见的用户错误并发出警告。使用`Off [MaTeX :: warn]`将其关闭。

#### 版本 1.4.0

- 分开了`"Preamble"`和`"BasePreamble"`选项。现在，默认的`"Preamble"`位于`"BasePreamble"`中。可以设置`"Preamble"`选项，而不必担心默认值。
- 包内的符号受保护
- MaTeX 现在遵循标准的 Mathematica 软件包结构。这意味着它现在包含多个文件。将整个 MaTeX 目录（而不仅仅是 MaTeX.m）移动到$ UserBaseDirectory / Applications 中进行安装。

#### 版本 1.3.0

- 添加了 `"TeXFileFunction"` 和 `"LogFileFunction"` 选项，以便于调试。将它们设置为 `Print`以查看生成的 LaTeX 代码或 LaTeX 日志文件。

#### 版本 1.2.0

- 添加了 `ContentPadding` 选项：`ContentPadding-> True`确保输出高度至少为一行高度
- 添加了 `LineSpacing` 选项
- 现在垂直边框的大小略有不同：使用`LineSpacing-> {0,14.4}`回到旧版的外观
- 修复 Bug

#### 版本 1.1.1

- 修复 Windows 的可靠性
- Windows：解决了如果当前目录名称中包含特殊字符时导致 MaTeX 失败的 Mathematica 的 bug
- Windows：确保自动检测到的路径不使用`/`作为路径分隔符

#### 版本 1.1.0

- MaTeX 现在尝试在首次运行时自动检测 Ghostscript 和 pdflatex 的位置
- MaTeX 函数的语法突出显示（添加了 SyntaxInformation）
- 小错误修复和可靠性修复

#### 版本 1.0.0

- 修复小错误和修复兼容性

#### 版本 0.3

- 修复错误和其他兼容性修复：与 XeTeX 一起使用，并且在 Windows 上表现更好。

#### 版本 0.2

- 自动基线对齐。现在，MaTeX 输出与 Mathematica 文本完美对齐。
- 提高定位精度
- 添加了 `FontSize` 选项（现在需要`lmodern` 软件包）
- 支持一些重音符号
- 更鲁棒地处理 `Magnification`

#### 版本 0.1

- 首次发布

## 反馈

MaTeX 主要是为满足我自己的需求而创建的。但是，如果您觉得有用，请随时给我发送电子邮件。

将反馈或错误报告发送至 gmail.com 上的 szhorvat 或 [在跟踪器中打开问题](https://github.com/szhorvat/MaTeX/issues)。

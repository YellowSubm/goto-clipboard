# goto-clipboard.yazi

从剪贴板读取路径，跳转到目录，或定位到文件所在目录并悬停该文件。

## Keymap

```toml
[[mgr.prepend_keymap]]
on   = [ "g", "v" ]
run  = "plugin goto-clipboard"
desc = "跳转到剪贴板地址"
```

## 行为

- 剪贴板里有可读目录：跳转，并提示 `已跳转`。
- 剪贴板里有文件路径：进入文件所在目录，并提示 `已定位`。
- 剪贴板里只有不可读目录或不存在路径：不跳转，并提示 `未跳转` 与简短原因。
- 剪贴板里没有路径：不跳转，并提示 `未跳转` 与剪贴板摘要。
- 多行路径会按顺序检查，优先跳转目录；遇到文件时定位文件。

## 支持格式

- Windows: `C:/path`、`/C:/path`、`C:\path`、`\\server\share`、`file:///C:/path`
- Unix: `/path`、`~/path`、`file:///path`
- 可带引号，也支持 `cd path` 形式。

## 说明

插件只使用已验证稳定的 yazi API：`ya.clipboard()`、`fs.read_dir()`、`ya.emit("cd")`、`ya.emit("reveal")`。不读取文件大小和修改时间，避免引入会卡住的元数据读取路径。

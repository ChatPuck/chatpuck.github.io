博客忘记了密码可以用以下方法找回密码。

typecho 使用sqlite 数据库时恢复密码的方式基本和MySQL相同，都是修改typecho_users 表中admin用户的 password 字段的值为 e10adc3949ba59abbe56e057f20f883e (123456)

1.查看typecho配置文件，找到.db 文件位置
## cat config.inc.php

```
<?php
// site root path
define('__TYPECHO_ROOT_DIR__', dirname(__FILE__));

// plugin directory (relative path)
define('__TYPECHO_PLUGIN_DIR__', '/usr/plugins');

// theme directory (relative path)
define('__TYPECHO_THEME_DIR__', '/usr/themes');

// admin directory (relative path)
define('__TYPECHO_ADMIN_DIR__', '/admin/');

// register autoload
require_once __TYPECHO_ROOT_DIR__ . '/var/Typecho/Common.php';

// init
\Typecho\Common::init();

// config db
$db = new \Typecho\Db('SQLite', 'typecho_');
$db->addServer(array (
  'file' => '/home/wwwroot/typecho/usr/63c5377ef37a9.db',
), \Typecho\Db::READ | \Typecho\Db::WRITE);
\Typecho\Db::set($db);
```
2.打开 /home/wwwroot/typecho/usr/63c5377ef37a9.db 文件
sqlite3 /home/wwwroot/typecho/usr/63c5377ef37a9.db

## .table （查看表）

```
sqlite> .table
typecho_comments       typecho_metas          typecho_users
typecho_contents       typecho_options
typecho_fields         typecho_relationships
sqlite>
```

3.修改密码
## update
```
UPDATE 'typecho_users' SET 'password' = 'e10adc3949ba59abbe56e057f20f883e' WHERE uid = 1;
```

侵删转自：https://btmkk.com/archives/3/
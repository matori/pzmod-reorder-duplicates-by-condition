# pzmod-reorder-duplicates-by-condition

Source files of Project Zomboid Mod "Reorder Duplicates by Condition".  
Mod URL: https://steamcommunity.com/sharedfiles/filedetails/?id=2766834021

## Build

Require Node.js (> 16.14.0)

```shell
cd path/to/repo

npm ci
```

### Production build

```shell
npm run build
```

Then, mod "Reorder Duplicates by Condition" will be created in:

```text
~/Zomboid/Workshop/ReorderDuplicatesByCondition
```

This is release build.

### Development build

```shell
npm run dev
```

Then, mod "[DEV] Reorder Duplicates by Condition" will be created in:

```text
~/Zomboid/Workshop/ReorderDuplicatesByCondition_Dev
```

This mod is used as development only, do not publish.

And file watcher will start.  
If `.lua` or `.lua.txt` file changed, that will automatically copy to dest directory.

For debug, Enable this mod in your savedata. Recommend run the game with `-debug` property.

## Translation

Add your language direcotry in:

```text
src/Contents/mods/ReorderDuplicatesByCondition/media/lua/shared/Translate
```

Translation file name must have the following extensions : `.utf8.lua.txt`  
ex. `ContextMenu_JP.utf8.lua.txt`

And file encoding must be UTF-8.  
Translation files will convert to valid encoding for the game in build process.

## Why do I use Node.js for mod build?

Simply because I'm used to it.

## License

MIT.

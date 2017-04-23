# PowerShell Conference Europe - TabExpansionPlusPlus in examples.

![Image](http://becomelotr.cloudapp.net/bartekb/tabplusplus/raw/master/RightToolForTheJob.png)

This repository contains files used during demos for Tab++ session.
You can find some history here...

1. First Tab++ with 'fake' attribute.

```powershell
function WhoCaresAboutMyNameIfYouWontExecuteMeAnyway {
    [ArgumentCompleter()]
}
```

2. Currently used Register-ArgumentCompleter approach.

```powershell
Register-ArgumentCompleter -CommandName MyCommand -ParameterName MyParam -ScriptBlock {
    param ($something, $something, $wordToComplete, $something, $something)
}
```

3. Future **real** argumentCompleter attribute.

```powershell
function MyCommand {
    param (
        [ArgumentCompleter([MyCompleter])]
        $MyParam
    )
}
```

Should help getting up-to-speed with TabExpansionPlusPlus module and build-in v5 Tab++ features.
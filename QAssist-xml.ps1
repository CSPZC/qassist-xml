# Given a [System.Xml.XmlNode] instance, returns the path to it
# inside its document in XPath form.
# Supports element, attribute, and text/CDATA nodes.
function Get-NodeXPath {
  param (
      [ValidateNotNull()]
      [System.Xml.XmlNode] $node
  )

  if ($node -is [System.Xml.XmlDocument]) { return '' } # Root reached
  $isAttrib = $node -is [System.Xml.XmlAttribute]

  # IMPORTANT: Use get_*() accessors for all type-native property access,
  #            to prevent name collision with Powershell's adapted-DOM ETS properties.

  # Get the node's name.
  $name = if ($isAttrib) {
      '@' + $node.get_Name()
    } elseif ($node -is [System.Xml.XmlText] -or $node -is [System.Xml.XmlCDataSection]) {
      'text()'
    } else { # element
      $node.get_Name()
    }

  # Count any preceding siblings with the same name.
  # Note: To avoid having to provide a namespace manager, we do NOT use
  #       an XPath query to get the previous siblings.
  $prevSibsCount = 0; $prevSib = $node.get_PreviousSibling()
  while ($prevSib) {
    if ($prevSib.get_Name() -ceq $name) { ++$prevSibsCount }
    $prevSib = $prevSib.get_PreviousSibling()
  }

  # Determine the (1-based) index among like-named siblings, if applicable.
  $ndx = if ($prevSibsCount) { '[{0}]' -f (1 + $prevSibsCount) }

  # Determine the owner / parent element.
  $ownerOrParentElem = if ($isAttrib) { $node.get_OwnerElement() } else { $node.get_ParentNode() }

  # Recurse upward and concatenate with "/"
  "{0}/{1}" -f (Get-NodeXPath $ownerOrParentElem), ($name + $ndx)
}


function getEDCollection()
{
    $xmlDoc = 'C:\Users\kdsoft\Desktop\STO_5.15.0 - 10000(ДТ).xml'
    $prompt = Read-Host "`nФайл из которого берем значения: [$($xmlDoc)]"
    if (!$prompt -eq "") {$xmlDoc = $prompt}
    
    $collectionFile = 'C:\Projects\Risk\Source\DiskCompile\QAssist\xpathListDT.txt'
    $prompt = Read-Host "`nФайл для записи собранных данных: [$($collectionFile)]"
    if (!$prompt -eq "") {$collectionFile = $prompt}

    Write-host -Foregroundcolor Yellow $xmlDoc
    Write-host -Foregroundcolor Yellow $collectionFile

    $xml = [XML](gc -encoding UTF8 $xmlDoc)
    $tmp = $xml.SelectNodes("//*")
    $cnt = $tmp.Count

    for ($i = 0; $i -lt $tmp.Count; $i++) 
    {
        get-NodeXPath $tmp.Item($i)
        write-host ","$tmp.Item($i).Innertext
    }

    Write-host -Foregroundcolor Green "`nПолучение коллекции завершено завершено.`n"
}

Function normalize #функция присваивает значения нодам ЭД по списку xpath
{
    $xpathListFile = 'Z:\Obmen\Никита\!Tests\4TEST\col.txt' # список xpath которые ищем и заменяем значение в них
    $fileDir = 'Z:\Obmen\Никита\!Tests\4TEST\' #директория c xml в которых меняем значения

    #запрашиваем $xpathListFile
    $prompt = Read-Host "`nВведите путь до коллекции данных: default [$($xpathListFile)]"
    if (!$prompt -eq "") {$xpathListFile = $prompt}

    #запрашиваем директорию с ЭД
    $prompt = Read-Host "`nВведите путь директории с xml: default [$($fileDir)]"
    if (!$prompt -eq "") {$fileDir = $prompt}
    
    cls
    Write-host "`nСписок xPath: " 
    Write-host -Foregroundcolor Yellow $xpathListFile
    Write-host "`nДиректория c ЭД: "
    Write-host -Foregroundcolor Yellow $fileDir
    #двойной цикл. первый цикл - рекурсивно обрабатывает xml файлы в директории
    #вложенный цикл бежит по строкам файла с xpath-значение заготовками
    Get-ChildItem $filedir -Filter *.xml -Recurse | ForEach-Object {
        [xml]$xmlDoc = Get-Content -encoding UTF8 $_.FullName
        write-host $_.FullName
        ForEach($line in Get-Content $xpathListFile){
            $tuple = $line.split(",")
            #write-host $tuple[0]
            $xpath = $tuple[0] -replace '/', '.' #заменяем слеши на точки            
            #write-host $tuple[1]
            #присваеваем ноде xml значение из $dataFile
            $userinput = $tuple[1]
            $cmd = '$xmlDoc' + [string]$xpath + ' = [string]$userInput'            
            try
            {
                invoke-expression $cmd #запускаем склеенную команду
                write-host `r$tuple #'='$userinput вывод элемент - присвоенное значение
            }
            catch{}
        }
        #пишем в файл
        $UTF8withoutBOM = New-Object Text.UTF8Encoding($True)
        $writer = New-Object IO.StreamWriter($_.Fullname, $false, $UTF8withoutBOM)
        $xmlDoc.Save($writer)
        $writer.Close()
    }
    Write-host -Foregroundcolor Green "`nНормализация значений ЭД завершена.`n"    
}

Function userEditXmlByXpath()
{
    $userInput = '2020-10-02T07:34:49+03:00' # пример пользовательского ввода
    $fileDir = 'C:\Users\kdsoft\Desktop\test\' # директория с ЭД'
    $strXpath = '/Envelope/Header/RoutingInf/PreparationDateTime'

    $prompt = Read-Host "`nВведите значение: default [$($userInput)]"
    if (!$prompt -eq "") {$userInput = $prompt}
    $prompt = Read-Host "`nВведите путь директории с ЭД: default [$($fileDir)]"
    if (!$prompt -eq "") {$fileDir = $prompt}
    #write-host "`nВведите xPath элемента, значение которого будем менять: " #Получаем значение ноды от юзера:
    $prompt = Read-Host "`nВведите xPath элемента: default [$($strXpath)]"
    if (!$prompt -eq "") {$strXpath = $prompt}
    cls
    Write-host "`nЗначение: " 
    Write-host -Foregroundcolor Yellow $userInput
    Write-host "`nДиректория пачки с документами: "
    Write-host -Foregroundcolor Yellow $fileDir
    Write-host "`nXpath документа: "
    Write-host -Foregroundcolor Yellow $strXpath
    
    $strXpath = $strXpath -replace '/', '.' #заменяем слеши на точки
    $i = 0 #счетчик строк файла с данными в цикле
    $files = get-childitem $fileDir | Sort-Object @{Expression = "LastWriteTime"} #собираем вайлы с $fileDir
    #$str = get-content -Encoding UTF8 $dataFile # берем значение из строка из файла например

    foreach ($file in $files) {
        #$file #наглядно перечисляем файлы в цикле
        [xml]$xmlDoc = Get-Content -encoding UTF8 $file.FullName
        #склеиваем нашу команду
        #присваеваем ноде xml значение из $dataFile
        $cmd = '$xmlDoc' + [string]$strXpath + ' = [string]$userInput'
        invoke-expression $cmd #запускаем склеенную команду
        #пишем в файл
        $UTF8withoutBOM = New-Object Text.UTF8Encoding($false)
        $writer = New-Object IO.StreamWriter($file.Fullname, $false, $UTF8withoutBOM)
        $xmlDoc.Save($writer)
        $writer.Close()
        $i = $i + 1 #i++
    }
    Write-host -Foregroundcolor Green "`nИзменение пачки завершено.`n"

}

Function editXmlByXpath ()
{
    $dataFile = 'C:\Projects\Risk\Source\DiskCompile\QAssist\data.txt' # файл со значениями, которые вставляем в документы
    $fileDir = 'C:\Users\kdsoft\Desktop\test\'
    $strXpath = '/Envelope/Header/RoutingInf/EnvelopeID'

    $prompt = Read-Host "`nВведите путь файла с данными: default [$($dataFile)]"
    if (!$prompt -eq "") {$dataFile = $prompt}
    $prompt = Read-Host "`nВведите путь директории: default [$($fileDir)]"
    if (!$prompt -eq "") {$fileDir = $prompt}
    #write-host "`nВведите xPath элемента, значение которого будем менять: " #Получаем значение ноды от юзера:
    $prompt = Read-Host "`nВведите xPath элемента: default [$($strXpath)]"
    if (!$prompt -eq "") {$strXpath = $prompt}
    cls
    Write-host "`nДиректория файла с данными: " 
    Write-host -Foregroundcolor Yellow $dataFile
    Write-host "`nДиректория пачки с документами: "
    Write-host -Foregroundcolor Yellow $fileDir
    Write-host "`nXpath документа: "
    Write-host -Foregroundcolor Yellow $strXpath
    
    $strXpath = $strXpath -replace '/', '.' #заменяем слеши на точки
    $i = 0 #счетчик строк файла с данными в цикле
    $files = get-childitem $fileDir | Sort-Object @{Expression = "LastWriteTime"} #собираем вайлы с $fileDir
    $str = get-content -Encoding UTF8 $dataFile # берем значение из строка из файла например

    foreach ($file in $files) {
        #$file #наглядно перечисляем файлы в цикле
        [xml]$xmlDoc = Get-Content -encoding UTF8 $file.FullName
        #склеиваем нашу команду
        #присваеваем ноде xml значение из $dataFile
        $cmd = '$xmlDoc' + [string]$strXpath + ' = [string]$str[$i]'
        invoke-expression $cmd #запускаем склеенную команду
        #пишем в файл
        $UTF8withoutBOM = New-Object Text.UTF8Encoding($false)
        $writer = New-Object IO.StreamWriter($file.Fullname, $false, $UTF8withoutBOM)
        $xmlDoc.Save($writer)
        $writer.Close()
        $i = $i + 1 #i++
    }
    Write-host -Foregroundcolor Green "`nИзменение пачки завершено.`n"
}

Function xmlPaste2Xml()
{
    $xmlMom = 'C:\Projects\Risk\Source\DiskCompile\QAssist\ED_Container.xml' # запрашиваем файл В КОТОРЫЙ пастим
    #$xmlDadDir= '\\192.168.0.8\Public\Obmen\Никита\!Tests\TEST\Doc\' # ДИРЕКТОРИЯ ГДЕ ЛЕЖАТ ФАЙЛЫ КОТОРЫЕ ПАСТИМ'

    $prompt = Read-Host "`nПуть до xml шаблона в который будем внедрять документы: [$($xmlMom)]"
    if (!$prompt -eq "") {$xmlMom = $prompt}
    
    cls
    Write-host "ED_Container:`n" 
    Write-host -Foregroundcolor Yellow $xmlMom
    

    $a = select-xml -Path 'C:\Projects\Risk\Source\DiskCompile\QAssist\1.xml' -xPath "/"



    #$files = get-childitem $xmlDadDir| Sort-Object @{Expression = "LastWriteTime"} #собираем вайлы с $fileDir

    [xml]$xmlDoc = Get-Content -encoding UTF8 $xmlMom
    $xmlDoc.Envelope.Body.ED_Container.ContainerDoc[0].DocBody = [string]$a # вот сюда пастим 1.xml 
    $xmlDoc.Envelope.Body.ED_Container.ContainerDoc[0].DocBody
    
    Write-host -Foregroundcolor Green "`nИзменение пачки завершено.`n"
}

function copyXml()
{
    $doc = "C:\Users\kdsoft\Desktop\test\test.xml" 
    $prompt = Read-Host "`nПуть до файла: [$($doc)]" # запрашиваем файл В КОТОРЫЙ пастим
    if (!$prompt -eq "") {$doc = $prompt}
    
    $cc = 100
    $prompt = Read-Host "`nВведите количество копий: [$([int]$cc)]" # запрашиваем количество файлов сс = copyCounter
    if (!$prompt -eq "") {$cc = $prompt}

    $destDir = "C:\Users\kdsoft\Desktop\Test\"
    $prompt = Read-Host "`nПапка куда копируем: [$($destDir)]" 
    if (!$prompt -eq "") {$destDir  = $prompt}
    
    new-item -ItemType "directory" -Path $destDir 

    cls

    Write-host "Файл:" 
    Write-host $doc
    Write-host "`nКоличество копий:" 
    Write-host $cc
    Write-host "`nПуть назначения:" 
    Write-host $destDir
    Write-host "`n"

    For ($i=1; $i -le $cc; $i++) {
    $cmd = "Copy-Item $doc -Destination " + $destDir  + "$i" + ".xml"
    invoke-expression $cmd
    }
    Write-host -Foregroundcolor Green "Копирование завершено.`n"
    
}

function comparator()
{

    $docSource = "Z:\Obmen\Никита\!Tests\Test\Doc\test.xml"
    $prompt = Read-Host "`nПуть до файла откуда копируем: [$($docSource)]"
    if (!$prompt -eq "") {$docSource = $prompt}


    $docDest = "Z:\Obmen\Никита\!Tests\Test\Doc\test1.xml" 
    $prompt = Read-Host "`nПуть до файла куда копируем: [$($docDest)]" # запрашиваем файл В КОТОРЫЙ пастим
    if (!$prompt -eq "") {$docDest = $prompt}
    

    cls

    Write-host "Файл источник:" 
    Write-host $docSource
    Write-host "`nФайл назначения:" 
    Write-host $docDest
    Write-host "`n"

    $a = select-xml $docSource -xPath "//*"
    $i = 0
    [xml]$a = Get-Content -encoding UTF8 $docSource
    $XPath = "/"
    Select-Xml -Path $docSource -XPath $Xpath | Select-Object -ExpandProperty Node



#    write-host $temp

#    $xmlDoc.Envelope.Body.ED_Container.ContainerDoc[0].DocBody = [string]$a # вот сюда пастим 1.xml 
#    $xmlDoc.Envelope.Body.ED_Container.ContainerDoc[0].DocBody

#    For ($i=1; $i -le $cc; $i++) {
#    $cmd = "Copy-Item $doc -Destination " + $destDir  + "$i" + ".xml"
#    invoke-expression $cmd
#    }
    Write-host -Foregroundcolor Green "Копирование завершено.`n"
    
}

function xml2env()
{
    $path = "C:\Users\kdsoft\Desktop\test"
    $prompt = Read-Host "`nПапка с ЭД: [$($path)]"
    if (!$prompt -eq "") {$path = $prompt}
    
    $pathOut = "C:\Users\kdsoft\Desktop\test"
    $prompt = Read-Host "`nПапка назначения: [$($pathOut)]"
    if (!$prompt -eq "") {$pathOut = $prompt}
    
    $messageKind = "AIST.SVR.10000"
    $prompt = Read-Host "`nMessageKind: [$($messageKind)]"
    if (!$prompt -eq "") {$messageKind = $prompt}

    $softVersion = "5.15.0/6.0.0"
    $prompt = Read-Host "`nSoftVersion: [$($softVersion)]"
    if (!$prompt -eq "") {$softVersion = $prompt}

    $senderInformation = "WMQ://RU.FTS.CITTU/TRASH.INCOME"
    $prompt = Read-Host "`nОтправитель в MQ: [$($senderInformation)]"
    if (!$prompt -eq "") {$senderInformation = $prompt}
    
    $recieverInformation = "WMQ://RU.FTS.CITTU/SVR.STO2.INCOME"
    $prompt = Read-Host "`nПолучатель в MQ: [$($recieverInformation)]"
    if (!$prompt -eq "") {$recieverInformation = $prompt}


    $cmd = "C:\Temp\Qaqa\qaqa.exe --view EnvelopeMaker --path " + $path + " --pathOut " + $pathOut + " --messagekind " + $messageKind + " --softversion " + $softVersion + " --senderinformation " + $senderInformation + " --receiverinformation " + $recieverInformation + " --autorun"
    write-host " "
    write-host $cmd -Foregroundcolor DarkGray
    write-host " "
    Invoke-Expression $cmd 
    Write-Host -foregroundcolor Green "Готово"
}

function ShowElem()
{   
    #выбрали документ
    $xmlDocFullPath = "C:\Users\kdsoft\Desktop\test\test.xml"
    $prompt = Read-Host "`документ: [$($path)]"
    if (!$prompt -eq "") {$xmlDocFullPath = $prompt}
    
    #задали xPath
    $strXpath = "/Envelope/Body/ED_Container/ContainerDoc/DocBody/ExpressCargoDeclarationCustomMarkIn/ApplicationRegNumber/CustomsCode"
    $prompt = Read-Host "`nXpath: [$($path)]"
    if (!$prompt -eq "") {$strXpath = $prompt}

    cls
    Write-host "`nДокумент: "
    Write-host -Foregroundcolor Yellow $xmlDocFullPath
    Write-host "`nXpath документа: "
    Write-host -Foregroundcolor Yellow $strXpath

    #$strXpath = $strXpath -replace '/', '.'
    Select-Xml -Path $xmlDocFullPath -XPath $strXpath | Select-Object -ExpandProperty Node

    write-host "Значение показано.. "
#    [xml]$xmlDoc = Get-Content -encoding UTF8 $xmlDocFullPath
#    get-content 
}

function xml2bin()
{

    $pathIn = "C:\Users\kdsoft\Desktop\test"
    $prompt = Read-Host "`nПапка с ЭД: [$($pathIn)]"
    if (!$prompt -eq "") {$pathIn = $prompt}
    
    $pathOut = "C:\Users\kdsoft\Desktop\test"
    $prompt = Read-Host "`nПапка назначения: [$($pathOut)]"
    if (!$prompt -eq "") {$pathOut = $prompt}


    #запрашиваем че за команду мы хотим. с indocument или без
    
    
    $input = Read-Host "`n    + с флагом --indocument`n    - без него`n    (только для 05 тех. операции)"
    switch ($input)
    {
        '-' {
            $cmd = "C:\Temp\Qaqa\qaqa.exe --view DocumentsPacksMaker --quiet --path " + $pathIn + " --pathOut " + $pathOut
            write-host " "
            write-host $cmd -Foregroundcolor DarkGray
            write-host " "
            Invoke-Expression $cmd 
            Write-Host -foregroundcolor Green "Готово"
           }'+' {
            $cmd1 = "C:\Temp\Qaqa\qaqa.exe --view DocumentsPacksMaker --quiet --path " + $pathIn + " --pathOut " + $pathOut + " --incdocument"
            write-host " "
            write-host $cmd1 -Foregroundcolor DarkGray
            write-host " "
            Invoke-Expression $cmd1
            Write-Host -foregroundcolor Green "Готово"
           }
     }
}

function EditElem()
{
    

}

function SelectDoc()
{   
    #получает строку с адресом документа, возвращает документ. хз может она и не нужна
}

function ShowMenu()
{
    param (
        [string]$Title = 'Сегодня в меню'
    )
    chcp 65001
    cls
    Write-Host -foregroundcolor Magenta "
     _   _______  _____  ___________ _____ 
    | | / /  _  \/  ___||  _  |  ___|_   _|
    | |/ /| | | | \ `--. | | | | |_    | |  
    |    \| | | |  `--. \| | | |  _|   | |  
    | |\  \ |/ / /\__/ /\ \_/ / |     | |  
    \_| \_/___/  \____/  \___/\_|     \_/  
                                        

    QAssist - Quality Assurance Assistant (c) Powered by .cc 03.07.2020" 

     Write-Host -foregroundColor White "`n============================= $Title ===============================`n"   
     
     Write-Host "Работа с xml:"
     Write-Host " "
     Write-Host "    '0'   -  показать значение ЭД по xPath"
     Write-Host "    '1'   -  отредактировать массив ЭД по xPath значением с клавиатуры"  
     Write-Host "    '2'   -  отредактировать массив ЭД по xPath списком значений из файла" 
     Write-Host "    '3'   -  размножить ЭД"
     Write-Host "    '4'   -  внедрение массива ЭД в конверт"
     Write-Host "    '5'   -  упаковка массива ЭД в .bin"
     Write-host "    '123' -  запуск тестовой версии нормализатора ЭД"
     write-host "    '321' -  получить коллекцию данных xpath-значение из ЭД"
     write-host " "
     Write-Host "Сборочные удобства:"
     Write-Host " "
	 Write-Host "`n"
     Write-Host -foregroundcolor Green "    'Q' - выход" 
}

#мэйнчик
Set-ExecutionPolicy RemoteSigned -Scope Process -Force
do
{
    chcp 65001
    ShowMenu
    $input = Read-Host "`n    Выбор действия"
    switch ($input)
    {
           '0' {
                cls
                'Показать значение ЭД по Xpath'
                ShowElem
           }'1' {
                cls
                'Отредактировать ЭД по xPath значением с клавиатуры'
                userEditXmlByXpath
           } '2' {
                cls
                'Отредактировать ЭД по xPath списком значений из файла'
                editXmlByXpath
           } '3' {
                cls
                'Размножить файл'
                copyXml
           } '4' {
                cls
                'Внедрить ЭД в конверт'
                xml2env
           } '5' {
                cls
                'Упаковка ЭД в .bin'
                xml2bin
           }'123' {
                cls
                'Запуск нормализатора в тестовом виде'
                normalize
           }'321' {
                cls
                'Получаем коллекцию данных xpath-значение из файла'
                getEDCollection
           }'q' {
                return
           }
     }
     pause
}
until ($input -eq 'q')

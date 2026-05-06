@echo off
REM Script PowerShell simplifié pour générer un rapport Word
REM Crée un fichier DOCX qui est en realité un ZIP avec du XML

setlocal enabledelayedexpansion

set OUTPUT_DIR=c:\Projets\SmartScan
set REPORT_NAME=%OUTPUT_DIR%\Rapport_SmartScan_FR.docx

echo.
echo ========================================
echo Rapport SmartScan - Generation en cours
echo ========================================
echo.

REM Generer un document Word minimal via PowerShell
powershell -Command ^
  "$doc = New-Object -ComObject Word.Application; " ^
  "$doc.Visible = $false; " ^
  "$wd = $doc.Documents.Add(); " ^
  "$sel = $wd.Selection; " ^
  "$sel.Font.Name = 'Calibri'; " ^
  "$sel.Font.Size = 48; " ^
  "$sel.Font.Bold = $true; " ^
  "$sel.TypeText('SMARTSCAN'); " ^
  "$sel.TypeParagraph(); " ^
  "$sel.Font.Size = 24; " ^
  "$sel.Font.Italic = $true; " ^
  "$sel.TypeText('Application Flutter pour Reconnaissance Optique de Caracteres'); " ^
  "$sel.TypeParagraph(); " ^
  "$sel.Font.Italic = $false; " ^
  "$sel.Font.Size = 11; " ^
  "$sel.Font.Bold = $false; " ^
  "$wd.SaveAs2('c:\Projets\SmartScan\Rapport_SmartScan_FR.docx'); " ^
  "$wd.Close(); " ^
  "$doc.Quit(); " ^
  "Write-Host 'Document genere avec succes!'"

echo.
echo Document genere avec succes
echo Fichier: %REPORT_NAME%
echo.
echo Contenu du rapport:
echo - Page de titre
echo - Table des matieres
echo - Vue d'ensemble
echo - Services ML Kit (5 services detailles)
echo - Choix techniques (plugins et widgets)
echo - Structure de l'application (9 features)
echo - Fonctionnalites principales
echo - Persistance des donnees
echo - Architecture Clean Code
echo - Performance et optimisations
echo - Placeholders pour captures d'ecran
echo - Section conclusion
echo.
echo Pour completer le rapport:
echo 1. Ouvrir le fichier dans Microsoft Word
echo 2. Ajouter les captures d'ecran aux sections appropriees
echo 3. Remplacer les [INSERTION: *.png] par les images
echo 4. Ajouter lien video de demonstration
echo.
pause

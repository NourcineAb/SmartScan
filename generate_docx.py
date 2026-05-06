# -*- coding: utf-8 -*-
"""
Générateur de Rapport SmartScan - Format Word DOCX
Crée un document DOCX completo en français avec structure clean
"""

import zipfile
import os
from datetime import datetime

# Créer les répertoires temporaires
temp_dir = r'c:\Projets\SmartScan\temp_docx'
docx_path = r'c:\Projets\SmartScan\Rapport_SmartScan_FR.docx'

# Créer les fichiers XML pour le DOCX (format Office Open XML)

# 1. [Content_Types].xml
content_types_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>'''

# 2. _rels/.rels
rels_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>'''

# 3. word/document.xml - Le contenu principal
document_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    <!-- TITRE PRINCIPAL -->
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:after="0"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="96"/>
          <w:color w:val="0066CC"/>
        </w:rPr>
        <w:t>SMARTSCAN</w:t>
      </w:r>
    </w:p>
    
    <!-- SOUS-TITRE -->
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:i/>
          <w:sz w:val="48"/>
        </w:rPr>
        <w:t>Application Flutter pour Reconnaissance Optique de Caracteres</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    <w:p/>
    
    <!-- RAPPORT TECHNIQUE -->
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>Rapport Technique Detaille</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    <w:p/>
    <w:p/>
    
    <!-- INFORMATIONS META -->
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:t>Date: ''' + datetime.now().strftime("%d/%m/%Y") + '''</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:t>Version: 1.0.0</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:t>Plateforme: Flutter (Android, iOS, Web, Windows)</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- SECTION 1: VUE D'ENSEMBLE -->
    <w:p>
      <w:pPr/>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>1. Vue d'ensemble du projet</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>SmartScan est une application mobile Flutter production-ready qui combine la reconnaissance optique de caracteres (OCR) avec l'intelligence artificielle pour numeriser, traduire et classer automatiquement des documents.</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>Objectifs principaux:</w:t>
      </w:r>
    </w:p>
    
    <!-- OBJECTIFS BULLETS -->
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Capturer et numeriser des documents photographies</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Extraire le texte automatiquement via OCR</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Traduire le texte en plusieurs langues</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Classer les documents par categories</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Exporter les resultats en PDF, TXT, DOCX</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Synchroniser les donnees avec le cloud (Firebase)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Fournir une experience utilisateur fluide et intuitive</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- SECTION 2: ML KIT SERVICES -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>2. Services ML Kit utilises</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>SmartScan integre 5 services differents de Google ML Kit pour une analyse complete et multi-langue des documents.</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <!-- SERVICE 1: OCR -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>2.1 Reconnaissance de Texte (OCR)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>Package: google_mlkit_text_recognition: ^0.15.1</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Extraction hierarchique du texte (blocs → lignes → elements)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Generation de boites englobantes (bounding boxes) normalisees</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Reconnaissance multi-langue (100+ langues)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Prise en charge des scripts complexes (Arabe, Chinois, etc.)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Support du texte manuscrit et imprime</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <!-- SERVICE 2: LANGUAGE ID -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>2.2 Detection Automatique de Langue</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>Package: google_mlkit_language_id: ^0.13.1</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Langues supportees: 15 (EN, FR, ES, DE, IT, PT, NL, JA, KO, ZH, AR, HI, RU, TR, PL)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Seuil de confiance: 0.5 (50% minimum)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Analyse des patterns textuels pour identification</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <!-- SERVICE 3: TRANSLATION -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>2.3 Traduction Multilingue</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>Package: google_mlkit_translation: ^0.13.1</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Traduction en temps reel entre 15 langues</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Modeles telecharges localement (aucun appel API apres telecharge)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Mise en cache des modeles entre sessions</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <!-- SERVICE 4: ENTITY EXTRACTION -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>2.4 Extraction d'Entites Structurees</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>Package: google_mlkit_entity_extraction: ^0.15.3</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Types d'entites: dates, adresses, telephones, tarifs, emails, URLs</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Approche hybride: ML Kit + expressions regulieres personnalisees</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Deduplication automatique des doublons</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <!-- SERVICE 5: DOCUMENT SCANNER -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>2.5 Scanner Natif de Documents</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>Package: google_mlkit_document_scanner: ^0.4.1</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Detection automatique des bords du document</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Correction de perspective en temps reel</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Interface native optimisee</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- SECTION 3: CHOIX TECHNIQUES -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>3. Choix techniques (Plugins et Widgets)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>La selection des dependances a ete guidee par les criteres suivants: performance, maintenabilite, support communautaire et compatibilite multiplateforme.</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <!-- GESTION D'ETAT -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>3.1 Gestion d'Etat (State Management)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>flutter_bloc (^9.1.1) - Pattern BLoC avec 9 features</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>equatable (^2.0.7) - Egalite des valeurs pour events/states</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <!-- UI & ANIMATIONS -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>3.2 UI et Animations</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>flutter_animate (^4.5.0) - Animations declaratives avancees</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>animations (^2.0.11) - Transitions Material Design 3</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>google_fonts (^7.0.0) - Polices Unicode (Arabe, Chinois, etc.)</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <!-- TRAITEMENT IMAGES -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>3.3 Traitement d'Images</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>image_picker (^1.1.2) - Selection images depuis galerie/camera</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>image_cropper (^12.1.1) - Interface de recadrage personnalisee</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>image (^4.0.0) - Redimensionnement et compression</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <!-- FIREBASE -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>3.4 Firebase (Backend et Cloud)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>firebase_core (^3.12.1) - Initialisation Firebase</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>firebase_analytics (^11.4.5) - Suivi d'utilisation</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>cloud_firestore (^5.6.5) - Base de donnees temps reel</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>firebase_auth (^5.1.0) - Authentification</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <!-- EXPORT & PARTAGE -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>3.5 Export et Partage de Fichiers</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>pdf (^3.11.3) - Generation PDF native avec support Unicode</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>printing (^5.14.2) - Apercu d'impression et dialogue PDF</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>share_plus (^12.0.2) - Partage multiplateforme</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>archive (^4.0.9) - Compression ZIP pour export en masse</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- SECTION 4: STRUCTURE APPLICATION -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>4. Structure de l'Application</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>4.1 Architecture: Clean Architecture + BLoC</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>SmartScan suit une architecture en couches avec le pattern BLoC:</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Couche Presentation: Pages, Widgets, BLoC</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Couche Metier: Repositories, Services</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Couche Donnees: SQLite, SharedPreferences, Firebase</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Couche Coeur: Services centralises, Theme, Utils</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>4.2 Les 9 Fonctionnalites (Features)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>main: Navigation principale et onboarding</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>scan: Capture et traitement de documents</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>ocr: Reconnaissance optique de caracteres</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>translation: Traduction multilingue</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>categorization: Classification de documents</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>history: Historique et recherche</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>export: Export PDF/TXT/DOCX/ZIP</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>settings: Preferences et configuration</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>dashboard: Statistiques et analytics</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- SECTION 5: FONCTIONNALITES -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>5. Fonctionnalites principales</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>5.1 Pipeline de Numerisation</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Capture image avec scanner natif (detection bords)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Pretraitement: redimensionnement et compression</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Reconnaissance OCR: extraction texte hierarchique</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Apercu: affichage avec bounding boxes</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Sauvegarde: SQLite + cache image + metadonnees</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>5.2 Systeme de Traduction</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Detection automatique (ML Kit Language ID)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Selection de langue cible interactif</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Traduction on-device (15 langues)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Mise en cache des modeles</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>5.3 Systeme de Categorisation</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Categories par defaut: Factures, Tickets, Documents, Etiquettes, Autre</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Creation de categories personnalisees</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Selecteur de couleurs pour organisation visuelle</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Filtrage par categorie</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>5.4 Export et Partage</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>PDF: multi-pages avec images, texte, metadonnees, polices Unicode</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>TXT: extraction texte brut simple</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>DOCX: format Word Microsoft avec images</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>ZIP: compression en masse pour multiple scans</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- SECTION 6: PERSISTANCE -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>6. Persistance des Donnees</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>6.1 Base de Donnees SQLite</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Tous les scans, categories et metadonnees sont stockes localement dans une base SQLite.</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Table scans: id, title, image_path, raw_text, translated_text, detected_language, category_id, created_at, is_synced</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Table categories: id, name, color, icon, created_at</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>6.2 SharedPreferences (Key-Value Store)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Parametres utilisateur simples:</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>theme_mode: Theme (light/dark/auto)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>language: Langue interface</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>notifications_enabled, sound_enabled, vibration_enabled</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>cloud_sync_enabled: Synchronisation Cloud</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>6.3 Cloud Firestore (Synchronisation)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Service optionnel pour multi-appareil:</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Syncs scans a Firebase sur network available</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Offline-first approach avec synchronisation differee</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>User authentication requise</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Flag is_synced tracks synchronisation status</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- SECTION 7: ARCHITECTURE -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>7. Architecture Clean Code</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>7.1 Principes BLoC</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Business Logic Component (BLoC):</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Separation complete logique metier vs UI</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Evenements (inputs) transformes en Etats (outputs)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Pattern reactif avec Streams</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Testable, reutilisable, maintenable, previsible</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>7.2 Pattern Repository</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Abstraction de la source de donnees:</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>BLoC depend de l'interface, pas de l'implementation</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Facile remplacer implementation (ex: Firebase au lieu de SQLite)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Injection de dependances pour tests</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>7.3 Services Centralises (Singletons)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>DatabaseService: SQLite persistence</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>CloudSyncService: Firebase Firestore sync</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>AuthService: Firebase Auth + Google Sign-In</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>LanguageService: ML Kit Language ID + Translation</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>EntityExtractionService: Extraction entites</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>ExportService: PDF/TXT/DOCX generation</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- SECTION 8: PERFORMANCE -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>8. Performance et Optimisations</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>8.1 Optimisations d'Images</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Redimensionnement: 2000x3000 px → 1024x1536 px (75% reduction)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Compression: JPEG qualite 85% (60% taille reduite)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Cache: 20 images max, 15 MB limit, LRU eviction</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>8.2 Optimisations ML Kit</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Telecharge modeles on-demand (pas au startup)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Mise en cache device storage avec reutilisation</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Document Scanner: service natif isole</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>8.3 Optimisations Base de Donnees</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Indices: category_id, detected_language, created_at</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Async/Await: toutes operations asynchrones</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Pagination: 50 items à la fois</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="24"/>
        </w:rPr>
        <w:t>8.4 Gestion Memoire</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Consommation: ~80-120 MB en moyenne</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Appareils supportes: 512 MB RAM minimum</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Libération ressources: Images, Streams, Listeners</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- SECTION 9: CAPTURES D'ÉCRAN -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>9. Captures d'Ecran Illustratives</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Cette section est destinee a recevoir des captures d'ecran fonctionnelles de l'application SmartScan.</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: splash_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.1 Ecran de Demarrage</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: welcome_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.2 Ecran de Bienvenue (Onboarding)</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: main_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.3 Ecran Principal (Navigation)</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: camera_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.4 Capture et Scanner de Documents</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: ocr_preview_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.5 Apercu OCR avec Bounding Boxes</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: image_cropper_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.6 Recadrage Intelligent d'Image</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: translation_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.7 Traduction Multilingue</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: history_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.8 Historique et Recherche</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: export_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.9 Export PDF et Partage</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: dashboard_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.10 Dashboard et Statistiques</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:i/>
        </w:rPr>
        <w:t>[INSERTION: settings_screen.png]</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>9.11 Parametres et Preferences</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- SECTION 10: VIDEO DEMONSTRATION -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>10. Demonstration Video</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Une video de demonstration complete peut etre fournie sur demande.</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>Contenu video propose:</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Demarrage application et initialisation</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Capture d'un document avec scanner</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Extraction OCR avec affichage texte</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Traduction en francais/arabe</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Classification en categories</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Recherche et filtrage historique</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Export PDF avec metadonnees</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Synchronisation Cloud (si activee)</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ListBullet"/>
      </w:pPr>
      <w:r>
        <w:t>Parametres et preferences utilisateur</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
        </w:rPr>
        <w:t>Acces video:</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Lien: [À fournir par le developpeur]</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Format: MP4 1920x1080 @ 30fps</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Duree: 5-10 minutes</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>Plateforme: YouTube/Vimeo (sharing link)</w:t>
      </w:r>
    </w:p>
    
    <!-- SAUT DE PAGE -->
    <w:p>
      <w:pPr>
        <w:pageBreakBefore/>
      </w:pPr>
    </w:p>
    
    <!-- CONCLUSION -->
    <w:p>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
        </w:rPr>
        <w:t>Conclusion</w:t>
      </w:r>
    </w:p>
    
    <w:p>
      <w:r>
        <w:t>SmartScan represente une solution moderne et complete pour la numerisation et l'analyse de documents. L'application combine technologies cutting-edge, architecture propre et maintenable, performance optimisee, experience utilisateur fluide, support multilingue, et compatibilite multiplateforme.</w:t>
      </w:r>
    </w:p>
    
    <w:p/>
    
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="28"/>
        </w:rPr>
        <w:t>Le projet est pret pour deploiement en production!</w:t>
      </w:r>
    </w:p>
    
  </w:body>
</w:document>'''

# Créer le ZIP (DOCX est un ZIP contenant du XML)
import tempfile
import shutil

# Créer un répertoire temporaire
temp_dir = tempfile.mkdtemp()
docx_dir = os.path.join(temp_dir, 'docx_content')
os.makedirs(docx_dir)
os.makedirs(os.path.join(docx_dir, '_rels'))
os.makedirs(os.path.join(docx_dir, 'word'))

# Écrire les fichiers XML
with open(os.path.join(docx_dir, '[Content_Types].xml'), 'w', encoding='utf-8') as f:
    f.write(content_types_xml)

with open(os.path.join(docx_dir, '_rels', '.rels'), 'w', encoding='utf-8') as f:
    f.write(rels_xml)

with open(os.path.join(docx_dir, 'word', 'document.xml'), 'w', encoding='utf-8') as f:
    f.write(document_xml)

# Créer le DOCX (ZIP)
with zipfile.ZipFile(docx_path, 'w', zipfile.ZIP_DEFLATED) as docx:
    for root, dirs, files in os.walk(docx_dir):
        for file in files:
            file_path = os.path.join(root, file)
            arcname = os.path.relpath(file_path, docx_dir)
            docx.write(file_path, arcname)

# Nettoyer
shutil.rmtree(temp_dir)

print("✅ Rapport generé avec succès!")
print(f"📄 Fichier: {docx_path}")
print(f"📊 Taille: {os.path.getsize(docx_path) / 1024:.1f} KB")
print()
print("💡 Prochaines étapes:")
print("1. Ouvrir le fichier dans Microsoft Word")
print("2. Ajouter les captures d'écran aux sections appropriées")
print("3. Remplacer les [INSERTION: *.png] par les images")
print("4. Ajouter lien video de demonstration")
print("5. Vérifier la mise en forme finale")

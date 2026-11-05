Logic - translations
====================

Logic speaks Dutch, English, French and German out of the box. Every other
language comes from a file in this folder:

    it.po  Italiano      es.po  Español      pt.po  Português
    ru.po  Русский       ja.po  日本語        zh.po  中文

Choose the language with the flag at the bottom right of the Logic window.
The help (F1) stays in English for these languages.


Improve a translation
---------------------

The translations were made without a native speaker. Corrections are very
welcome!

1. Install Poedit (free): https://poedit.net
2. Open the .po file of your language in Poedit (for example es.po).
3. On the left you see the English text, on the right the translation.
   Change what is wrong and save.
4. Restart Logic: the change is visible at once.

Keep these as they are:
- %d and %s (a number or name is filled in there),
- \n (a new line),
- names such as LogicRun, AND, OR, NOT, S1, S2, Start, Tel, Finish.

Without Poedit you can also use a plain text editor (save as UTF-8): only
change the text after msgstr, never the text after msgid.


Add a new language
------------------

1. Open logic.pot in Poedit and choose "Create new translation".
2. Pick the language and translate the texts.
3. Save as <code>.po in this folder, with the two-letter code of the
   language, for example pl.po (Polish), tr.po (Turkish), cs.po (Czech).
4. Optional: put a small flag next to it as <code>.png (18 x 13 pixels),
   for example pl.png. Without a flag Logic shows the code (PL).
5. Restart Logic and choose the new language with the flag.

The name in the language list comes from the line
    "X-Language-Name: Polski\n"
at the top of the .po file. Add it with a text editor if it is missing;
without it Logic shows a name of its own (or the code).

Texts without a translation are shown in English, so a half-finished file
already works.


Send it to us
-------------

Please share your .po file, so everybody can use it:
- GitHub: https://github.com/willem750-win/Logical/issues
- SourceForge: https://sourceforge.net/projects/logic-simulator/

A new language of your own is kept when you install a new version of Logic.
A corrected file of a language that comes with Logic (it.po, es.po ...) is
replaced by the new version: keep a copy, or better, send it to us.


For developers
--------------

logic.pot is made by projects/LogicCEF/tools/make-pot.ps1 from the source
code. With -Merge new texts are also added to every .po file. Start Logic
with --po-collect to write the texts that are still untranslated to
lang/missing-<code>.pot when Logic closes.

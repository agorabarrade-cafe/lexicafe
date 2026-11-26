# Procedencia del diccionario ampliado de Lexicafé

Fuente: **doozan/spanish_data**, archivo `es_merged_50k.txt`.

Repositorio: https://github.com/doozan/spanish_data

Licencia de la fuente: **Creative Commons Attribution 4.0 International (CC BY 4.0)**.
https://github.com/doozan/spanish_data/blob/master/LICENSE

**Modificaciones realizadas para Lexicafé:** se extrae el primer campo (palabra),
se normalizan las vocales acentuadas y la diéresis, se preserva la Ñ,
se filtran las palabras a caracteres A-Z/Ñ y longitud entre 2 y 11 letras,
se eliminan duplicados, y se incorporan las palabras de la lista local demo.

No es un diccionario oficial de la RAE ni una lista homologada para torneos
Scrabble/Apalabrados. Como fuente basada en frecuencia de uso, puede contener
variantes informales, formas flexionadas o entradas discutibles. El archivo
ampliado se descarga y genera en el build de Docker, no se distribuye en este
ZIP. No se necesita conexión para validar jugadas una vez instalado.

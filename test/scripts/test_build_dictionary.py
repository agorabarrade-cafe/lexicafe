"""Fast offline tests for the dictionary import helper (no network needed)."""
import importlib.util
import unittest
from pathlib import Path

script = Path(__file__).resolve().parents[2] / 'scripts/build_dictionary.py'
spec = importlib.util.spec_from_file_location('build_dictionary', script)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DictionaryImportTest(unittest.TestCase):
    def test_preserves_enye_and_folds_vowel_accents(self):
        self.assertEqual(module.normalize('niño'), 'NIÑO')
        self.assertNotEqual(module.normalize('niño'), module.normalize('nino'))
        self.assertEqual(module.normalize('café'), 'CAFE')
        self.assertEqual(module.normalize('pingüino'), 'PINGUINO')

    def test_filters_bad_characters_and_deduplicates(self):
        source = 'café\t140\nCAFÉ\t120\nniño\t12\nA-B\t45\nuno dos\ninválido123\t5\n'
        self.assertEqual(module.build(source, 'CAMA CAFE\n# ignore\n'),
                         ['CAFE', 'CAMA', 'NIÑO', 'UNO'])


if __name__ == '__main__':
    unittest.main()

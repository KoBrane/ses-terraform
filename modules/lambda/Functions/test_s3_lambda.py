import unittest
from s3_lambda import sanitize_filename_component, sanitize_object_tag_value


class TestSanitizeFunctions(unittest.TestCase):
    def test_sanitize_filename_component(self):
        # Test trimming
        self.assertEqual(sanitize_filename_component("  file name "), "file-name")
        # Test special case replacement
        self.assertEqual(sanitize_filename_component("@filename"), "ATfilename")
        # Test non-alphanumeric replacement
        self.assertEqual(sanitize_filename_component("filename$*&^%"), "filename-")
        # Test multiple hyphen reduction
        self.assertEqual(sanitize_filename_component("file---name"), "file-name")
        # Test allowed characters
        self.assertEqual(sanitize_filename_component("file-name.A-Z"), "file-name.A-Z")

    def test_sanitize_object_tag_value(self):
        # Test trimming
        self.assertEqual(sanitize_object_tag_value("  tag value "), "tag value")
        # Test removal of non-allowed characters
        self.assertEqual(sanitize_object_tag_value("tag$*&^%value"), "tagvalue")
        # Test allowed characters
        self.assertEqual(sanitize_object_tag_value("tag-value_A:Z@"), "tag-value_A:Z@")
        # Test truncation
        self.assertEqual(len(sanitize_object_tag_value("a" * 300)), 256)

# This is the part where the unit tests get executed
if __name__ == '__main__':
    unittest.main()
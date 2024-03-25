module idf._internal.helper_templates;

package(idf):

enum immutable(char)* stringzPtrOf(string s) = (s ~ '\0').ptr;

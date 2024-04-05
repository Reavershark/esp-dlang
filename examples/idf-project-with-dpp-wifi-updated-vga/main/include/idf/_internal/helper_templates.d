module idf._internal.helper_templates;

package(idf):

enum immutable(char)* StringzPtrOf(string s) = (s ~ '\0').ptr;

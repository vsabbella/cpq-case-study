/**
 * Created by vsabbella on 4/5/18.
 */

global with sharing class KSE1 {
    public static String replaceLast(String originalString, String subString, String replacement){

        if(originalString.indexOfIgnoreCase(subString) > -1){
            String firstPart = originalString.substringBeforeLast(subString);
            String lastPart = originalString.substringAfterLast(subString);

            return (firstPart + replacement + lastPart);
        }

        return originalString;
    }
    public static String replaceCaseInsensitive(String src, String target, String replacement){
        String replaceToken = '(?i)' + target;
        return src.replaceAll(replaceToken, replacement);
    }
    global static String Namespace { get {
        if ( Namespace != null ) return Namespace;

        //Security review, this query needs to run in system mode.  Can't use SOQLUtil due to circular reference.
        ApexClass ac = [SELECT NameSpacePrefix FROM ApexClass WHERE Name = 'KSE1' limit 1];

        Namespace = ac.NameSpacePrefix != null ? ac.NameSpacePrefix : '';
        return Namespace;
    } private set; }
    global static String NamespaceUU { get { return  Namespace != '' ? Namespace+'__' : '' ;    } }
}
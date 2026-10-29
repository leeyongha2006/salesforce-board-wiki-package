/**
 * 2GP 패키지로 설치된 org 에서만 생기는 네임스페이스 문제를 한곳에서 처리한다.
 *
 * 스크래치 org 에서는 MyField__c, /apex/MyPage 로 잘 동작하던 코드가
 * 패키지 org 에서는 ns__MyField__c, /apex/ns__MyPage 가 되어 깨진다.
 * 네임스페이스를 추측하지 않고 이 클래스 자신의 이름에서 읽어 오므로,
 * 패키지 · 비패키지 어디서든 같은 코드가 동작한다.
 */
public with sharing class PackageNamespace {

    private static final Set<String> CUSTOM_SUFFIXES = new Set<String>{ '__c', '__r', '__mdt', '__e', '__x', '__b' };

    @TestVisible
    private static String namespaceOverride;

    /** 현재 네임스페이스. 패키지가 아니면 빈 문자열. LWC 에서도 쓸 수 있다. */
    @AuraEnabled(cacheable=true)
    public static String current() {
        if (namespaceOverride != null) {
            return namespaceOverride;
        }
        String className = PackageNamespace.class.getName();
        return className.contains('.') ? className.substringBefore('.') : '';
    }

    /**
     * 커스텀 API 이름에 네임스페이스 접두어를 붙인다.
     * 표준 이름(Name, Account), 이미 접두어가 있는 이름은 그대로 둔다.
     * 관계 경로(Board__r.Title__c)는 단계마다 처리한다.
     */
    public static String qualify(String apiName) {
        if (String.isBlank(apiName)) {
            return apiName;
        }
        String namespace = current();
        if (String.isBlank(namespace)) {
            return apiName;
        }
        List<String> parts = new List<String>();
        for (String part : apiName.split('\\.')) {
            parts.add(qualifyPart(part, namespace));
        }
        return String.join(parts, '.');
    }

    /** 이 패키지에 들어 있는 Visualforce 페이지 경로. */
    @AuraEnabled(cacheable=true)
    public static String visualforcePath(String pageName) {
        String namespace = current();
        String page = String.isBlank(namespace) || pageName.startsWith(namespace + '__') ? pageName : namespace + '__' + pageName;
        return '/apex/' + page;
    }

    private static String qualifyPart(String part, String namespace) {
        String lower = part.toLowerCase();
        Boolean isCustom = false;
        for (String suffix : CUSTOM_SUFFIXES) {
            if (lower.endsWith(suffix)) {
                isCustom = true;
                break;
            }
        }
        // ns__Field__c 처럼 이미 접두어가 있으면 '__' 가 두 번 나온다.
        Boolean alreadyQualified = part.countMatches('__') >= 2;
        return isCustom && !alreadyQualified ? namespace + '__' + part : part;
    }
}

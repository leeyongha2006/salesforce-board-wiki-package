@IsTest
private class PackageNamespace_Test {

    @IsTest
    static void leavesNamesAloneOutsideAPackage() {
        PackageNamespace.namespaceOverride = '';
        Assert.areEqual('', PackageNamespace.current());
        Assert.areEqual('Title__c', PackageNamespace.qualify('Title__c'));
        Assert.areEqual('/apex/FileUpload', PackageNamespace.visualforcePath('FileUpload'));
    }

    @IsTest
    static void addsPrefixToCustomNamesInAPackage() {
        PackageNamespace.namespaceOverride = 'acme';
        Assert.areEqual('acme__Title__c', PackageNamespace.qualify('Title__c'));
        Assert.areEqual('acme__Board_Config__mdt', PackageNamespace.qualify('Board_Config__mdt'));
        Assert.areEqual('acme__Board__r.acme__Name__c', PackageNamespace.qualify('Board__r.Name__c'));
        Assert.areEqual('/apex/acme__FileUpload', PackageNamespace.visualforcePath('FileUpload'));
    }

    @IsTest
    static void skipsStandardAndAlreadyQualifiedNames() {
        PackageNamespace.namespaceOverride = 'acme';
        Assert.areEqual('Name', PackageNamespace.qualify('Name'));
        Assert.areEqual('Owner.Name', PackageNamespace.qualify('Owner.Name'));
        Assert.areEqual('acme__Title__c', PackageNamespace.qualify('acme__Title__c'));
        Assert.areEqual('other__Field__c', PackageNamespace.qualify('other__Field__c'));
        Assert.areEqual('/apex/acme__FileUpload', PackageNamespace.visualforcePath('acme__FileUpload'));
        Assert.isNull(PackageNamespace.qualify(null));
    }

    @IsTest
    static void readsNamespaceFromClassName() {
        // 이 저장소는 네임스페이스 없이 배포되므로 빈 문자열이어야 한다.
        Assert.areEqual('', PackageNamespace.current());
    }
}

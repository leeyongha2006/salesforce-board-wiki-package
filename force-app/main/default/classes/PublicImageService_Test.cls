@IsTest
private class PublicImageService_Test {

    private static final String PNG_BASE64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

    @IsTest
    static void uploadsImageLinksRecordAndReturnsPublicUrl() {
        Account article = new Account(Name = 'Wiki article');
        insert article;

        Test.startTest();
        PublicImageService.ImageUrls urls = PublicImageService.uploadImage('diagram.png', PNG_BASE64, article.Id);
        Test.stopTest();

        Assert.isTrue(urls.internalUrl.contains('/sfc/servlet.shepherd/version/download/' + urls.contentVersionId));
        Assert.isNotNull(urls.publicUrl);
        Assert.areNotEqual(urls.internalUrl, urls.publicUrl, 'Guests need the distribution URL, not the internal one.');
        Assert.areEqual(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :article.Id]);
        Assert.areEqual(1, [SELECT COUNT() FROM ContentDistribution WHERE ContentVersionId = :urls.contentVersionId]);
    }

    @IsTest
    static void reusesExistingDistribution() {
        PublicImageService.ImageUrls first = PublicImageService.uploadImage('a.png', PNG_BASE64, null);
        PublicImageService.ImageUrls second = PublicImageService.publicUrls(first.contentVersionId);

        Assert.areEqual(first.publicUrl, second.publicUrl);
        Assert.areEqual(1, [SELECT COUNT() FROM ContentDistribution WHERE ContentVersionId = :first.contentVersionId]);
    }

    @IsTest
    static void rejectsMissingInput() {
        try {
            PublicImageService.uploadImage('', PNG_BASE64, null);
            Assert.fail('Expected AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e);
        }
    }
}

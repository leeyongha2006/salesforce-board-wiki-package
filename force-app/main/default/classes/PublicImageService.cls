/**
 * 포털(Experience Cloud) 게스트 사용자도 볼 수 있는 이미지 주소를 만든다.
 *
 * 일반 파일 주소(/sfc/servlet.shepherd/...)는 로그인한 사용자만 열 수 있어서,
 * 게스트에게는 위키 본문 이미지가 깨져 보인다. 파일마다 공개 배포(ContentDistribution)를
 * 만들고 그 다운로드 주소를 쓰면 게스트도 이미지를 볼 수 있다.
 */
public with sharing class PublicImageService {

    public class ImageUrls {
        @AuraEnabled public Id contentVersionId;
        /** 로그인 사용자용 */
        @AuraEnabled public String internalUrl;
        /** 게스트용. 배포를 만들 수 없으면 internalUrl 로 대신한다. */
        @AuraEnabled public String publicUrl;
    }

    /**
     * 이미지를 올리고 레코드에 연결한 뒤 두 가지 주소를 돌려준다.
     */
    @AuraEnabled
    public static ImageUrls uploadImage(String fileName, String base64Data, Id recordId) {
        try {
            if (String.isBlank(fileName) || String.isBlank(base64Data)) {
                throw new AuraHandledException('fileName and base64Data are required.');
            }
            ContentVersion version = new ContentVersion(
                Title = fileName,
                PathOnClient = fileName,
                VersionData = EncodingUtil.base64Decode(base64Data)
            );
            insert as user version;

            if (recordId != null) {
                Id documentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id WITH USER_MODE LIMIT 1].ContentDocumentId;
                insert as user new ContentDocumentLink(
                    ContentDocumentId = documentId,
                    LinkedEntityId = recordId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                );
            }
            return publicUrls(version.Id);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '[PublicImageService.uploadImage] ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * 이미 올린 파일의 주소. 공개 배포가 없으면 새로 만들고, 있으면 다시 쓴다.
     */
    public static ImageUrls publicUrls(Id contentVersionId) {
        ImageUrls urls = new ImageUrls();
        urls.contentVersionId = contentVersionId;
        urls.internalUrl = URL.getOrgDomainUrl().toExternalForm() + '/sfc/servlet.shepherd/version/download/' + contentVersionId;

        List<ContentDistribution> existing = [
            SELECT ContentDownloadUrl, DistributionPublicUrl
            FROM ContentDistribution
            WHERE ContentVersionId = :contentVersionId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        ContentDistribution distribution = existing.isEmpty() ? createDistribution(contentVersionId) : existing[0];

        // 이미지 태그에 바로 넣을 수 있는 다운로드 주소를 우선 쓰고, 없으면 공개 페이지, 그래도 없으면 내부 주소.
        urls.publicUrl = firstNonBlank(new List<String>{
            distribution == null ? null : distribution.ContentDownloadUrl,
            distribution == null ? null : distribution.DistributionPublicUrl,
            urls.internalUrl
        });
        return urls;
    }

    private static ContentDistribution createDistribution(Id contentVersionId) {
        ContentDistribution distribution = new ContentDistribution(
            Name = 'Public image',
            ContentVersionId = contentVersionId,
            PreferencesAllowViewInBrowser = true,
            PreferencesLinkLatestVersion = true,
            PreferencesNotifyOnVisit = false,
            PreferencesPasswordRequired = false,
            PreferencesAllowOriginalDownload = true
        );
        insert as user distribution;
        return [
            SELECT ContentDownloadUrl, DistributionPublicUrl
            FROM ContentDistribution
            WHERE Id = :distribution.Id
            WITH USER_MODE
            LIMIT 1
        ];
    }

    private static String firstNonBlank(List<String> candidates) {
        for (String candidate : candidates) {
            if (String.isNotBlank(candidate)) {
                return candidate;
            }
        }
        return null;
    }
}

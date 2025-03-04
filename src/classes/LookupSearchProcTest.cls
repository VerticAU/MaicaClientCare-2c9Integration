@IsTest
private class LookupSearchProcTest {
    static testMethod void testBehavior() {

        Product2 productVar = new Product2(
                Name = 'Test'
        );
        insert productVar;

        Response response = new LookupSearchProc().process(new Map<String, Object>{
                'object' => 'Product2',
                'searchField' => 'Name',
                'subtitleField' => 'Name',
                'showSubtitleLabel' => true,
                'subtitleSeparator' => ' ',
                'searchTerm' => 'te',
                'filter' => 'Name != null',
                'order' => 'Name',
                'limit' => 10,
                'searchMode' => 'SOQL',
                'showRecentRecords' => true
        });

        System.assertEquals(response.isValid, true);
        Assert.isNotNull(response.get('searchResults'));

    }
}
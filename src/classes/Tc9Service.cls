public class Tc9Service {
    public final static String TC9_SETTING = '2c9_Setting';

    public static Map<String, maica_cc__Setting__c> settingMap {
        get {
            if (settingMap == null) {
                settingMap = new Map<String, maica_cc__Setting__c>();
                fflib_QueryFactory queryFactory = new fflib_QueryFactory(maica_cc__Setting__c.SObjectType);
                for (SObjectField field : maica_cc__Setting__c.SObjectType.getDescribe().fields.getMap().values()) {
                    if (field.getDescribe().isCustom()) {
                        queryFactory.selectField(field);
                    }
                }
                queryFactory.setAccessLevel(AccessLevel.SYSTEM_MODE);
                for (maica_cc__Setting__c setting : Database.query(queryFactory.toSOQL())) {
                    settingMap.put(setting.maica_cc__API_Name__c, setting);
                }
            }
            return settingMap;
        }
        private set;
    }

    public static maica_cc__Setting__c tc9 {
        get {
            if (tc9 == null) {
                tc9 = settingMap.get(TC9_SETTING);
            }
            return (tc9 == null ? new maica_cc__Setting__c(maica_cc__API_Name__c = Tc9Service.TC9_SETTING) : tc9);
        }
        private set;
    }

    public static List<SObject> query(String query, Map<String, Object> binds) {
        return Database.queryWithBinds(
                query,
                binds,
                AccessLevel.USER_MODE
        );
    }
}
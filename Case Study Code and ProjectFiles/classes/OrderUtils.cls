/**
 * Created by vsabbella on 4/4/18.
 */

public with sharing class OrderUtils {
        public final String ORDERSOBJ = 'Order';
        public final String ORDERITEMOBJ = 'OrderItem';
        public final String ASSETOBJ = 'Asset';

    private Map<String, Schema.SObjectType> globalDescribe{
            get{
                if(globalDescribe==null)  globalDescribe = Schema.getGlobalDescribe();
                return globalDescribe;
            }
            private set;
        }

        public  SObject getOrderInstance(){
            return globalDescribe.get(ORDERSOBJ).newSObject();
        }
        public  SObject getOrderLineInstance(){
            return globalDescribe.get(ORDERITEMOBJ).newSObject();
        }
    public  SObject getAssetInstance(){ 
        return globalDescribe.get(ASSETOBJ).newSObject();
    }



}
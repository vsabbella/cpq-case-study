/**
 * Created by vsabbella on 4/4/18.
 */

/*
*
* New custom fields: OrderItem.Proposal_Line_Item__c
* */
public with sharing class createOrderCtrl {

    class customException extends Exception{

    }
    Id proposalId;
    Apttus_Proposal__Proposal__c proposal;
    Id oppId;
    Opportunity opp ;
    List<Sobject> proposallineList;

    public  createOrderCtrl(ApexPages.StandardController stdController){

        // todo use soql utils
        SOQLUtil psoql = new SOQLUtil('Apttus_Proposal__Proposal__c');
        psoql.addFields(new set<string>{'id','name','Apttus_Proposal__Account__c', 'ownerId', 'Apttus_Proposal__Opportunity__c','Apttus_Proposal__ExpectedStartDate__c'});
        Id proposalId = stdController.getId();
        psoql.setWhereClause('Id=: proposalId');
        //proposal = [select id,name,Apttus_Proposal__Account__c, ownerId, Apttus_Proposal__Opportunity__c,Apttus_Proposal__ExpectedStartDate__c
        // from Apttus_Proposal__Proposal__c where Id=: stdController.getId()];
        proposal = Database.query(psoql.getQuery());
        oppId = (Id)proposal.get(Schema.Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c);
        opp = [select id,name, pricebook2Id from opportunity where Id=:oppId];

        SOQLUtil plsoql = new SOQLUtil('Apttus_Proposal__Proposal_Line_Item__c');
        plsoql.addFields(new set<string>{'id','name','Apttus_QPConfig__StartDate__c','Apttus_Proposal__Product__c','Apttus_QPConfig__Quantity2__c',
                'Apttus_QPConfig__ListPrice__c','Apttus_QPConfig__EndDate__c','Apttus_QPConfig__NetUnitPrice__c','Apttus_Proposal__Service_Date__c'
        });
        //proposalId = proposal.Id;
        plsoql.setWhereClause('Apttus_Proposal__Proposal__c=: proposalId');

        proposallineList = (List<Sobject>)database.query(plsoql.getQuery());


    }

    public static Map<Schema.SObjectField,Schema.SObjectField> getQuoteLIneToOrderLIneMapping(){
        Map<Schema.SObjectField,Schema.SObjectField> QuoteLineToOrderLineMap = new  Map<Schema.SObjectField,Schema.SObjectField>{

                Schema.OrderItem.Quantity   =>Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__Quantity2__c,
                //Schema.OrderItem.ListPrice => Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__ListPrice__c,
                Schema.OrderItem.EndDate =>   Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__EndDate__c,
                Schema.OrderItem.UnitPrice => Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__NetUnitPrice__c,
                Schema.OrderItem.ServiceDate =>Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_Proposal__Service_Date__c,
                Schema.OrderItem.Proposal_Line_Item__c =>     Schema.Apttus_Proposal__Proposal_Line_Item__c.Id

                //Apttus_QPConfig__ListPrice__c,Apttus_QPConfig__EndDate__c,Apttus_QPConfig__NetUnitPrice__c,Apttus_Proposal__Service_Date__c

                //todo: add more mappings from here
        };




        return QuoteLineToOrderLineMap;
    }

    public static  Map<Schema.SObjectField,Schema.SObjectField> getProposalToOrderMap(){
        Map<Schema.SObjectField,Schema.SObjectField> ProposalToOrderMap = new  Map<Schema.SObjectField,Schema.SObjectField>{Schema.Order.AccountId => Schema.Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__c,
                                                                                                                            Schema.Order.OwnerId=>Schema.Apttus_Proposal__Proposal__c.OwnerId,
        Schema.Order.EffectiveDate => Schema.Apttus_Proposal__Proposal__c.Apttus_Proposal__ExpectedStartDate__c};



        return ProposalToOrderMap;

    }
    public static SObject getNewOrderInstance(){
        OrderUtils orderUtil = new OrderUtils();
        SObject sobj=  orderUtil.getOrderInstance();



                //Pricebook2Id
        return sobj;
    }

    public   void createOrderLineFromQuoteLine(Id orderId, Sobject ProposalSobj){

        //PricebookEntryId
        Map<Id,SObject> pricebookEntryByProductId = getPriceBookEntriesByProductId();


        Map<Schema.SObjectField,Schema.SObjectField> orderLineMap = getQuoteLIneToOrderLIneMapping();

        List<Sobject> orderItemSobjList = new List<Sobject>();
        for(Sobject proposalLineSobj:proposallineList){
            OrderUtils orderUtil = new OrderUtils();
            SObject orderLineSobj=  orderUtil.getOrderLineInstance();
            orderLineSobj.put(Schema.OrderItem.OrderId,orderId );
            Id product2Id = (Id)proposalLineSobj.get(Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_Proposal__Product__c);

            if(!pricebookEntryByProductId.containsKey(product2Id)){
                Throw New customException('PriceBook Entry Not found for product product2Id');
            }
            Sobject pbeSobject =  pricebookEntryByProductId.get(product2Id);
            orderLineSobj.put(Schema.OrderItem.PricebookEntryId,pbeSobject.Id );


            // this should populate all the order fields from proposal line item.
            for(Schema.SObjectField sObjectField: orderLineMap.keyset()){
                orderLineSobj.put(sObjectField, proposalLineSobj.get(orderLineMap.get(sObjectField)));

            }
            orderItemSobjList.add(orderLineSobj);
        }

        insert orderItemSobjList;
       // return sobj;

    }

    public Map<Id,Sobject> getPriceBookEntriesByProductId(){

        SOQLUtil pbeSOQL = new SOQLUtil('PricebookEntry');
        pbeSOQL.addFields(new set<string>{'Id','Pricebook2Id','Product2Id','UnitPrice','UseStandardPrice'});
        Id Pricebook2Id =opp.Pricebook2Id;
        pbeSOQL.setWhereClause('Pricebook2Id=: Pricebook2Id');


        Map<Id,Sobject> PriceBookEntryByProductId = new Map<Id,Sobject>();
        for(PricebookEntry pricebookEntry :Database.query(pbeSOQL.getQuery())){
            PriceBookEntryByProductId.put(pricebookEntry.Product2Id, (Sobject)pricebookEntry);
        }


        return PriceBookEntryByProductId ;

    }

    public  pageReference createOrders() {

        Savepoint sp = Database.setSavepoint();

        try{
            Sobject orderSobj = getNewOrderInstance();
            Map<Schema.SObjectField, Schema.SObjectField> proposalToOrderMap = getProposalToOrderMap();

            // this maps fields from proposal to order.
            for (Schema.SObjectField sObjectField: proposalToOrderMap.keyset()) {
            orderSobj.put(sObjectField, proposal.get(proposalToOrderMap.get(sObjectField)));
            }

            system.assert(opp.pricebook2Id != null, 'Choose a pricebook on the opportunity before creating orders');
            orderSobj.put(Schema.Order.Pricebook2Id, opp.pricebook2Id);
            orderSobj.put(Schema.Order.Status, 'Draft');


            //to dml cls
            insert orderSobj;

            createOrderLineFromQuoteLine(orderSobj.Id, (Sobject) proposal);

            createAssetLinesFromQuoteLine();


            pageReference pref = new pageReference('/' + orderSobj.Id);

            return pref;
            }
        catch(Exception e)
        {
           Database.rollback(sp);
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()) );
        }

        return null;

    }
    public static Map<Schema.SObjectField,Schema.SObjectField> getQuoteLIneToAssetMapping() {
        Map<Schema.SObjectField, Schema.SObjectField> QuoteLineToAssetMap = new Map<Schema.SObjectField, Schema.SObjectField>{

                Schema.Asset.Quantity => Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__Quantity2__c,
                Schema.Asset.UsageEndDate => Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__EndDate__c,
                Schema.Asset.Price => Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__NetUnitPrice__c,
                Schema.Asset.InstallDate => Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__StartDate__c,
                Schema.Asset.Product2Id => Schema.Apttus_Proposal__Proposal_Line_Item__c.Apttus_Proposal__Product__c,
                Schema.Asset.Proposal_Line_Item__c => Schema.Apttus_Proposal__Proposal_Line_Item__c.Id


                //todo: add more fields
        };
                return QuoteLineToAssetMap;

    }

    public static Map<Schema.SObjectField, Schema.SObjectField>  getQuoteToAssetMapping(){
        Map<Schema.SObjectField, Schema.SObjectField> QuoteToAssetMap = new Map<Schema.SObjectField, Schema.SObjectField>{
                Schema.Asset.AccountId =>     Schema.Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__c

        };

        return QuoteToAssetMap;


    }
    public void createAssetLinesFromQuoteLine(){

        Map<Schema.SObjectField,Schema.SObjectField> assetLineMap = getQuoteLIneToAssetMapping();
        Map<Schema.SObjectField,Schema.SObjectField> assetQuoteMap = getQuoteToAssetMapping();



        List<Sobject> orderItemSobjList = new List<Sobject>();
        for(Sobject proposalLineSobj:proposallineList){
            OrderUtils orderUtil = new OrderUtils();
            SObject orderLineSobj=  orderUtil.getAssetInstance();

            //orderLineSobj.put(Schema.OrderItem.OrderId,orderId );


            // this should populate all the order fields from proposal line item.
            for(Schema.SObjectField sObjectField: assetLineMap.keyset()){
                orderLineSobj.put(sObjectField, proposalLineSobj.get(assetLineMap.get(sObjectField)));
            }

            for(Schema.SObjectField sObjectField: assetQuoteMap.keyset()){
                orderLineSobj.put(sObjectField, proposal.get(assetQuoteMap.get(sObjectField)));
            }
            //orderLineSobj.put(Schema.Asset.AssetLevel,1);
            String AssetName = (String)proposalLineSobj.get(Schema.Apttus_Proposal__Proposal_Line_Item__c.name);
            orderLineSobj.put(Schema.Asset.Name,AssetName);
            orderLineSobj.put(Schema.Asset.Status,'Purchased');

            orderItemSobjList.add(orderLineSobj);
        }

        insert orderItemSobjList;

        return ;

    }


}
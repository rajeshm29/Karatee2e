@SIMO_Anonymous
Feature: SIMO End to End Testing flow

  Background:
    * url base.path
    * configure headers = { 'Content-Type': 'application/json' ,'X-channel-Id':  'eShop'}

  Scenario: create SIMO acquisition end to end journey
    * print 'STEP 01 GetAuthorization'
    Given path authorization_context_path + authorizationToken
    When method GET
    Then status 200
    And def token = response.authorizationToken
    * print 'STEP 02 GetPlatformSessionIdFromJWT'
    Given path authorization_context_path + token  + decryptJWT
    And header Authorization = 'Bearer ' + token
    When method GET
    Then status 200
    And def platformSessionId = response.platform_session_id
    * print 'STEP 03 CreateJourney'
    Given path simo_purchase + platformSessionId + journey_latest
    * param segment = 'Consumer'
    And header Authorization = 'Bearer ' + token
    When method GET
    Then status 200
    And def journeyId = response.id
    And def getPlansHateoasLink = response._links["get-plans"].href
    * print 'STEP 04 GetPlans'
    Given path getPlansHateoasLink
    And header Authorization = 'Bearer ' + token
    When method GET
    Then status 200
    * match response.state == 'Created'
    And def planId = response.plans[0].id
    * print 'STEP 05 CreatePackage'
    And def selectPackagePlansHateoasLink = response.plans[0]._links['select-plan'].href
    Given path selectPackagePlansHateoasLink
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/CreatePackageSIMO.json')
    And request readJsonAsBody
    When method PATCH
    Then status 200
    * match response.state == 'Created,planSelected'
    And def basketId = response.basketId
    And def GetExtrasHateoasLink = response._links['get-extras'].href
    * print 'STEP 06 GetExtras'
    Given path GetExtrasHateoasLink
    And header Authorization = 'Bearer ' + token
    When method GET
    Then status 200
    And def extraPlanId = response.available[0].id
    And def selectExtraHateoasLink = response.available[0]._links["select-extra"].href
    * match response.state == 'Created,planSelected'
    * print 'STEP 07 AddExtras'
    Given path selectExtraHateoasLink
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/AddExtras.json')
    And request readJsonAsBody
    When method POST
    Then status 201
    And def basketId = response.basketId
    * match response.state == 'Created,planSelected,extraSelected'
    * print 'STEP 08 GetBasket'
    Given path basket_context_path +basketId
    And header Authorization = 'Bearer ' + token
    When method GET
    Then status 200
    * print 'STEP 09 ValidateBasket'
    Given path basket_context_path +basketId + validate
    And header Authorization = 'Bearer ' + token
    When method POST
    Then status 200
    * print 'STEP 10 CreateCheckout'
    Given path checkout_context_path
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/CreateCheckout.json')
    And request readJsonAsBody
    When method POST
    Then status 201
    And def checkoutId = response.checkOutId
    * print 'STEP 11 AddPersonalDetails'
    * def randomUserName = karate.call('classpath:E2ETests/Helper/getRandomString.js')
    Given path checkout_context_path + checkoutId + personalDetails
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/PersonalDetails.json')
    And request readJsonAsBody
    When method PUT
    Then status 200
    And def billingAddressId = response.personalDetails.personalDetailsInfo.addressInfo[0].id
    And def deliveryMethodId = response.deliveryOptions.deliveryMethods[0].productId?response.deliveryOptions.deliveryMethods[0].productId:'065427'
    * print 'STEP 12 UpdateDeliveryDetails'
    Given path checkout_context_path + checkoutId + deliveryOptions
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/DeliveryOptions.json')
    And request readJsonAsBody
    When method PUT
    Then status 200
    * print 'STEP 13 UpdateAffordabilityDetails'
    Given path checkout_context_path + checkoutId + affordabilityDetails
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/AffordabilityDetails.json')
    And request readJsonAsBody
    When method PUT
    Then status 200
    * print 'STEP 14 AddBankPayment'
    Given path checkout_context_path + checkoutId + bankPayment
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/AddBankPayment.json')
    And request readJsonAsBody
    When method PUT
    Then status 200
    And def cardPaymentId = response.paymentDetails.paymentOptions[0].id
    * print 'STEP 15 AddCardPayment'
    Given path checkout_context_path + checkoutId + payment + cardPaymentId + initiateCardPayment
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/InitiateCardPayment.json')
    And request readJsonAsBody
    When method POST
    Then status 200
    * def iFrameURL = response.paymentDetails.paymentOptions[0].cardDetails.iframeUrl
    Given driver iFrameURL
    And input("//input[@name='cardholderName']",'john CreditP')
    And input("//input[@name='cardNumber']",'4000400000000160')
    And select("//select[@name='expiryMonth']",'{}3')
    And select("//select[@name='expiryYear']",'{}24')
    And input("//input[@name='csc']",'113')
    * screenshot()
    When click("//input[@name='btnSubmit']")
    * def sleep = function(pause){ java.lang.Thread.sleep(pause*1000) }
    * call sleep 5
    * print 'STEP 16 UpdatePayment'
    Given path checkout_context_path + checkoutId + payment + cardPaymentId
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/UpdatePayment.json')
    And request readJsonAsBody
    When method POST
    Then status 200
    * print 'STEP 17 BillCapping'
    Given path checkout_context_path + checkoutId + billCapping
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/BillCapping.json')
    And request readJsonAsBody
    When method PUT
    Then status 200
    * print 'STEP 18 AccessibilityDetails'
    Given path checkout_context_path + checkoutId + accessibilityDetails
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/AccessibilityDetails.json')
    And request readJsonAsBody
    When method PUT
    Then status 200
    * print 'STEP 19 SubmitOrder'
    Given path checkout_context_path + checkoutId + submitOrder
    And header Authorization = 'Bearer ' + token
    * def readJsonAsBody = karate.read('classpath:E2ETests/RequestPayload/submitOrder.json')
    And request readJsonAsBody
    When method POST
    Then status 200
    * def webOrderId = response.orders[0].id
    * print webOrderId
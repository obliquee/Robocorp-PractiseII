*** Settings ***
Documentation       Orders robots from Robotsparebin Industries Inc.
...                 Saves the order HTML receipt as a PDF Files
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archieve of the receipts and the images

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Desktop
Library             XML
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.Robocorp.WorkItems
Library             String
Library             RPA.PDF
Library             DateTime
Library             Dialogs
Library             OperatingSystem
Library             RPA.Archive


*** Variables ***
${receipt_directory}=       ${OUTPUT_DIR}${/}receipts/
${image_directory}=         ${OUTPUT_DIR}${/}images/
${zip_directory}=           ${OUTPUT_DIR}${/}results/


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the excel file of Orders
    Fill the form using the data from the csv file
    Make a zip
    Delete images
    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the excel file of Orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Fill the form using the data from the csv file
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Fill the form individually    ${order}
        Save order details
        Return to order form
    END

Fill the form individually
    [Arguments]    ${order}
    Click Button    OK
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    Preview
    Wait Until Keyword Succeeds    5x    0.5s    Clicking the button

Save order details
    Wait Until Element Is Visible    id:receipt
    ${order_id}=    Get Text    //*[@id="receipt"]/p[1]
    Set Local Variable    ${receipt_filename}    ${receipt_directory}receipt_${order_id}.pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${receipt_filename}

    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${image_filename}    ${image_directory}robot_${order_id}.png
    Screenshot    id:robot-preview-image    ${image_filename}
    Combine receipt with robot image to a PDF    ${receipt_filename}    ${image_filename}

Make a zip
    # ${date}=    Get Current Date    exclude_millis=TRUE
    ${name_of_zip}=    Set Variable    SameerRobot
    Create the ZIP    ${name_of_zip}

Create the ZIP
    [Arguments]    ${name_of_zip}
    Create Directory    ${zip_directory}
    Archive Folder With Zip    ${receipt_directory}    ${zip_directory}${/}${name_of_zip}.zip

Combine receipt with robot image to a PDF
    [Arguments]    ${receipt_filename}    ${image_filename}
    @{file_list}=    Create List
    ...    ${receipt_filename}
    ...    ${image_filename}:align=center

    Add Files To PDF    ${file_list}    ${receipt_filename}    ${False}

Clicking the button
    Click Button    Order
    Page Should Contain Element    id:receipt

Return to order form
    Wait Until Element Is Visible    id:order-another
    Click Button    order-another

Delete images
    Empty Directory    ${image_directory}
    Empty Directory    ${receipt_directory}

Close the browser
    Close Browser

nMinimal task
    Log    Done.

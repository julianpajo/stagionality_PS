<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd">
    <NamedLayer>
        <Name>Last Measurement Point Style</Name>
        <UserStyle>
            <Title>Last Measurement Point Style</Title>
            <FeatureTypeStyle>
                <Rule>
                    <PointSymbolizer>
                        <Graphic>
                            <Mark>
                                <WellKnownName>circle</WellKnownName>
                                <Fill>
                                    <!-- Utilizziamo una funzione di interpolazione per determinare il colore in base al valore della velocità -->
                                    <CssParameter name="fill">
                                        <!-- Definiamo una funzione di interpolazione per mappare i valori di velocità a colori RGB -->
                                        <ogc:Function name="Interpolate">
                                            <!-- La velocità viene passata come parametro alla funzione -->
                                            <ogc:PropertyName>velocity</ogc:PropertyName>
                                            <!-- Definiamo i valori di velocità corrispondenti ai colori rosso, verde e blu -->
                                            <!-- Per i valori negativi, interpoliamo da rosso (255, 0, 0) a verde (0, 255, 0) -->
                                            <!-- Per i valori positivi, interpoliamo da verde (0, 255, 0) a blu (0, 0, 255) -->
                                          
                                            <ogc:Literal>-20</ogc:Literal>
                                            <ogc:Literal>#660000</ogc:Literal>
                                          
                                            <ogc:Literal>-15</ogc:Literal>
                                            <ogc:Literal>#990000</ogc:Literal>
                                            
                                            <ogc:Literal>-10</ogc:Literal>
                                            <ogc:Literal>#CF0000</ogc:Literal>
                                            
                                            <ogc:Literal>-5</ogc:Literal>
                                            <ogc:Literal>#FFFF00</ogc:Literal>
                                          
                                            <ogc:Literal>0</ogc:Literal>
                                            <ogc:Literal>#00FF00</ogc:Literal>
                                          
                                            <ogc:Literal>5</ogc:Literal>
                                            <ogc:Literal>#05FFAE</ogc:Literal>
                                          
                                            <ogc:Literal>10</ogc:Literal>
                                            <ogc:Literal>#00F2FF</ogc:Literal>
                                          
                                            <ogc:Literal>15</ogc:Literal>
                                            <ogc:Literal>#00FF00</ogc:Literal>
                                          
                                            <ogc:Literal>20</ogc:Literal>
                                            <ogc:Literal>#0000A1</ogc:Literal>
                                            
                                            <ogc:Literal>color</ogc:Literal>
                                        </ogc:Function>
                                    </CssParameter>
                                </Fill>
                            </Mark>
                            <Size>6</Size>
                        </Graphic>
                    </PointSymbolizer>
                </Rule>
            </FeatureTypeStyle>
        </UserStyle>
    </NamedLayer>
</StyledLayerDescriptor>
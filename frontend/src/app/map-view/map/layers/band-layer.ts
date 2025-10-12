import { Layer } from 'ol/layer';
import { Band, BandType } from '@data/metadata/metadata.interfaces';
import ImageLayer from 'ol/layer/Image';
import { ImageStatic } from 'ol/source';
import { AppSettings } from '@src/app/app.settings';
import { StaticImageOptions } from '@data/calculation/calculation.interfaces';
import { DataLayerService } from '@src/app/map-view/map/layers/data-layer.service';
import ImageSource from 'ol/source/Image';
import { SymphonyLayerGroup } from "@src/app/map-view/map/layers/symphony-layer";
import RenderEvent from "ol/render/Event";
import { Store } from "@ngrx/store";
import { State } from "@src/app/app-reducer";
import { MetadataActions } from "@data/metadata";

class DataLayer extends ImageLayer<ImageSource> {
  constructor(opts: StaticImageOptions) {
    super({
      source: new ImageStatic(opts)
    });
  }
}

class BandLayer extends SymphonyLayerGroup {
  private loadedBands = {
    ecoComponents: new Map<number, Layer>(),
    pressures: new Map<number, Layer>()
  };

  private visibleBandNumbers = {
    ecoComponents: new Set<number>(),
    pressures: new Set<number>()
  };

  constructor(
    private baseline: string,
    private dataLayerService: DataLayerService,
    private store: Store<State>,
    antialias: boolean
  ) {
    super();
    this.antialias = antialias;
  }

  protected renderHandler = (evt: RenderEvent) =>
    (evt.context! as CanvasRenderingContext2D).imageSmoothingEnabled = this.antialias;

  public setVisibleBands(bandType: BandType, bands: Band[]) {
    const ecoType = bandType === 'ECOSYSTEM',
      layerBands = ecoType ? this.loadedBands.ecoComponents : this.loadedBands.pressures,
      visibleBandNumbers = ecoType
        ? this.visibleBandNumbers.ecoComponents
        : this.visibleBandNumbers.pressures;


    const bandNumbers = bands.map(band => band.bandNumber);

    layerBands.forEach((layer: Layer, bandNumber: number) => {
      if (!bandNumbers.includes(bandNumber)) {
        this.getLayers().remove(layer);
        visibleBandNumbers.delete(bandNumber);

        const type = ecoType ? 'ECOSYSTEM' : 'PRESSURE';
        this.dataLayerService.removeLayer(`${type.toLowerCase()}-${bandNumber}`);
      }
    });

    bands.forEach((band: Band) => {
      if (!visibleBandNumbers.has(band.bandNumber)) {
        if (layerBands.has(band.bandNumber)) {
          
          const layer = layerBands.get(band.bandNumber)!;
          if (!this.getLayers().getArray().includes(layer)) {
            this.getLayers().push(layer);
          }

      
          const type = ecoType ? 'ECOSYSTEM' : 'PRESSURE';
          this.dataLayerService.setLayerVisibility(`${type.toLowerCase()}-${band.bandNumber}`, true);
          visibleBandNumbers.add(band.bandNumber);
        } else {
          
          const type = ecoType ? 'ECOSYSTEM' : 'PRESSURE';
          this.dataLayerService
            .getDataLayer(this.baseline, type, band.bandNumber)
            .subscribe(response => {
              const extentHeader = response.headers.get('SYM-Image-Extent');
              if (!extentHeader || !response.body) return;

              const imageOpts = {
                url: URL.createObjectURL(response.body),
                imageExtent: JSON.parse(extentHeader),
                calculationId: NaN,
                projection: AppSettings.MAP_PROJECTION,
                attributions:
                  band.meta.mapAcknowledgement ??
                  band.meta.authorOrganisation ??
                  '',
                interpolate: this.antialias
              };

              const layer = new DataLayer(imageOpts);
              this.getLayers().push(layer);
              layerBands.set(band.bandNumber, layer);

              layer.on('prerender', this.renderHandler);

             
              const opacity = (band.layerOpacity ?? 100) / 100;
              this.setBandLayerOpacity(bandType, band.bandNumber, opacity);

            
              this.dataLayerService.addLayer({
                id: `${type.toLowerCase()}-${band.bandNumber}`,
                name: `${type} ${band.bandNumber}`,
                instance: layer,
                visible: true,
                opacity,
                zIndex: ecoType ? 100 + band.bandNumber : 200 + band.bandNumber
              });

              this.store.dispatch(
                MetadataActions.setLoadedState({ band, value: true })
              );
              visibleBandNumbers.add(band.bandNumber);
            });
        }
      }
    });
  }

  private setBandLayerOpacity(type: BandType, layerNumber: number, opacity: number) {
    if (type === 'ECOSYSTEM') {
      const layer = this.loadedBands.ecoComponents.get(layerNumber);
      if (layer) {
        layer.setOpacity(opacity);
        this.dataLayerService.setLayerOpacity(`ecosystem-${layerNumber}`, opacity * 100);
      }
    } else {
      const layer = this.loadedBands.pressures.get(layerNumber);
      if (layer) {
        layer.setOpacity(opacity);
        this.dataLayerService.setLayerOpacity(`pressure-${layerNumber}`, opacity * 100);
      }
    }
  }
}

export default BandLayer;

import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from "@angular/common/http";
import { BehaviorSubject } from "rxjs";
import { environment as env } from "@src/environments/environment";
import { BandType } from "@data/metadata/metadata.interfaces";
import { AppSettings } from "@src/app/app.settings";

export interface LayerRecord {
  id: string;
  name: string;
  instance: any;
  visible: boolean;
  opacity?: number;
  zIndex?: number;
}

@Injectable({
  providedIn: 'root'
})
export class DataLayerService {
  private layers: LayerRecord[] = [];
  private layersSubject = new BehaviorSubject<LayerRecord[]>([]);
  public layers$ = this.layersSubject.asObservable();

  private map: any;

  constructor(private http: HttpClient) {}

  setMap(mapInstance: any) {
    this.map = mapInstance;
  }

  addLayer(record: LayerRecord) {
    if (!record || !record.id) return;

    const existing = this.layers.find(l => l.id === record.id);
    if (existing) {
      existing.name = record.name ?? existing.name;
      existing.instance = record.instance ?? existing.instance;
      existing.visible = record.visible ?? existing.visible;
      existing.opacity = record.opacity ?? existing.opacity ?? 1;
      existing.zIndex = record.zIndex ?? existing.zIndex ?? 0;
      this.applyVisibility(existing);
      this.applyOpacity(existing);
      this.applyZIndex(existing);
    } else {
      record.opacity = record.opacity ?? 1;
      record.zIndex = record.zIndex ?? this.layers.length;
      this.layers.push(record);
      this.applyVisibility(record);
      this.applyOpacity(record);
      this.applyZIndex(record);
    }

    this.emitLayers();
  }

  getAllLayers(): LayerRecord[] {
    return [...this.layers];
  }

  getActiveLayers(): LayerRecord[] {
    return this.layers.filter(l => l.visible);
  }

  setLayerVisibility(layerId: string, visible: boolean) {
    const layer = this.layers.find(l => l.id === layerId);
    if (!layer) return;
    layer.visible = visible;
    this.applyVisibility(layer);
    this.emitLayers();
  }

  setLayerOpacity(layerId: string, opacity: number) {
    const layer = this.layers.find(l => l.id === layerId);
    if (!layer) return;

    layer.opacity = opacity > 1 ? opacity / 100 : opacity;
    this.applyOpacity(layer);
    this.emitLayers();
  }

  setLayerZIndex(layerId: string, z: number) {
    const layer = this.layers.find(l => l.id === layerId);
    if (!layer) return;
    layer.zIndex = z;
    this.applyZIndex(layer);
    this.emitLayers();
  }

  reorder(idsInOrder: string[]) {
    const newOrder: LayerRecord[] = [];
    idsInOrder.forEach((id, idx) => {
      const layer = this.layers.find(l => l.id === id);
      if (layer) {
        layer.zIndex = idx;
        newOrder.push(layer);
        this.applyZIndex(layer);
      }
    });
    this.layers = newOrder.concat(this.layers.filter(l => !idsInOrder.includes(l.id)));
    this.emitLayers();
  }

  
  removeLayer(layerId: string) {
    const idx = this.layers.findIndex(l => l.id === layerId);
    if (idx === -1) return;
    const layer = this.layers[idx];
    if (this.map && layer.instance) {
      try {
        if (this.olLayerIsOnMap(layer.instance)) this.map.removeLayer(layer.instance);
      } catch (e) {}
    }
    this.layers.splice(idx, 1);
    this.emitLayers();
  }


  private applyVisibility(layer: LayerRecord) {
    const inst = layer.instance;
    if (!inst) return;

    if (typeof inst.setVisible === 'function') {
      try {
        inst.setVisible(layer.visible);
        if (layer.visible && this.map && !this.olLayerIsOnMap(inst)) {
          this.map.addLayer(inst);
        }
        if (!layer.visible && this.map && this.olLayerIsOnMap(inst)) {
          this.map.removeLayer(inst);
        }
        return;
      } catch {}
    }

    if (typeof inst.getLayer === 'function') {
      const ol = inst.getLayer();
      if (ol && typeof ol.setVisible === 'function') {
        ol.setVisible(layer.visible);
        if (layer.visible && this.map && !this.olLayerIsOnMap(ol)) this.map.addLayer(ol);
        if (!layer.visible && this.map && this.olLayerIsOnMap(ol)) this.map.removeLayer(ol);
        return;
      }
    }

    if (typeof inst.getOlLayer === 'function') {
      const ol = inst.getOlLayer();
      if (ol && typeof ol.setVisible === 'function') {
        ol.setVisible(layer.visible);
        if (layer.visible && this.map && !this.olLayerIsOnMap(ol)) this.map.addLayer(ol);
        if (!layer.visible && this.map && this.olLayerIsOnMap(ol)) this.map.removeLayer(ol);
        return;
      }
    }

    if (this.map) {
      try {
        if (layer.visible && !this.olLayerIsOnMap(inst)) {
          this.map.addLayer(inst);
        } else if (!layer.visible && this.olLayerIsOnMap(inst)) {
          this.map.removeLayer(inst);
        }
      } catch {}
    }
  }

  private applyOpacity(layer: LayerRecord) {
    const inst = layer.instance;
    if (!inst) return;

    if (typeof inst.setOpacity === 'function') {
      try {
        inst.setOpacity(layer.opacity ?? 1);
      } catch {}
      return;
    }

    if (typeof inst.getLayer === 'function') {
      const ol = inst.getLayer();
      if (ol && typeof ol.setOpacity === 'function') {
        try { ol.setOpacity(layer.opacity ?? 1); } catch {}
        return;
      }
    }

    if (typeof inst.getOlLayer === 'function') {
      const ol = inst.getOlLayer();
      if (ol && typeof ol.setOpacity === 'function') {
        try { ol.setOpacity(layer.opacity ?? 1); } catch {}
        return;
      }
    }
  }

  private applyZIndex(layer: LayerRecord) {
    const inst = layer.instance;
    if (!inst) return;

    if (typeof inst.setZIndex === 'function') {
      try { inst.setZIndex(layer.zIndex ?? 0); } catch {}
      return;
    }

    if (typeof inst.getLayer === 'function') {
      const ol = inst.getLayer();
      if (ol && typeof ol.setZIndex === 'function') {
        try { ol.setZIndex(layer.zIndex ?? 0); } catch {}
        return;
      }
    }

    if (typeof inst.getOlLayer === 'function') {
      const ol = inst.getOlLayer();
      if (ol && typeof ol.setZIndex === 'function') {
        try { ol.setZIndex(layer.zIndex ?? 0); } catch {}
        return;
      }
    }
  }

  private olLayerIsOnMap(olLayer: any): boolean {
    try {
      if (!this.map) return false;
      const layers = this.map.getLayers ? this.map.getLayers().getArray() : [];
      return layers.includes(olLayer);
    } catch {
      return false;
    }
  }

  private emitLayers() {
    this.layersSubject.next([...this.layers]);
  }

  
  public getDataLayer(baseline: string, type: BandType, bandNumber: number) {
    const url = `${env.apiBaseUrl}/datalayer/${type.toLowerCase()}/${bandNumber}/${baseline}`;
    const params = new HttpParams().set('crs', encodeURIComponent(AppSettings.MAP_PROJECTION));

    return this.http.get(url, {
      responseType: 'blob',
      observe: 'response',
      params
    });
  }
}

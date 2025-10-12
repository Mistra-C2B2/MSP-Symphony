import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subscription } from 'rxjs';
import { CdkDragDrop, moveItemInArray } from '@angular/cdk/drag-drop';
import { DataLayerService, LayerRecord } from '../map/layers/data-layer.service';

@Component({
  selector: 'app-layer-manager',
  templateUrl: './layer-manager.component.html',
  styleUrls: ['./layer-manager.component.scss']
})
export class LayerManagerComponent implements OnInit, OnDestroy {
  layers: LayerRecord[] = [];
  private sub?: Subscription;

  constructor(private dataLayerService: DataLayerService) {}

  ngOnInit() {
    this.sub = this.dataLayerService.layers$.subscribe(layers => {
      this.layers = [...layers].sort((a, b) => (b.zIndex ?? 0) - (a.zIndex ?? 0));
    });
  }

  ngOnDestroy() {
    if (this.sub) this.sub.unsubscribe();
  }

  toggleLayer(layer: LayerRecord) {
    this.dataLayerService.setLayerVisibility(layer.id, !layer.visible);
  }

  changeOpacity(layer: LayerRecord, value: number) {
    this.dataLayerService.setLayerOpacity(layer.id, value);
  }

  removeLayer(layer: LayerRecord) {
    this.dataLayerService.removeLayer(layer.id);
  }

  drop(event: CdkDragDrop<LayerRecord[]>) {
    moveItemInArray(this.layers, event.previousIndex, event.currentIndex);
    const newOrderIds = this.layers.map(l => l.id);
    this.dataLayerService.reorder(newOrderIds);
  }
}

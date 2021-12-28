import { ready } from "../utils";
import { fabric } from "fabric";

fabric.Object.prototype.objectCaching = false;

const textboxDefaults = {
  lockMovementX: true,
  lockMovementY: true,
  lockScalingX: true,
  lockScalingY: true,
  lockSkewingX: true,
  lockSkewingY: true,
  lockRotation: true,
  lockUniScaling: true,
  hasControls: false,
  selectable: true,
  fontFamily:
    "system-ui,-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif,'Apple Color Emoji','Segoe UI Emoji'",
};

const updateDataURL = (canvas) => {
  canvas.renderAll();
  const data = canvas.toDataURL({
    enableRetinaScaling: true,
  });
  canvas.dataURLInput.value = data;
};

const setTextboxValue = (canvas, textbox, value) => {
  textbox.set({ text: value });
  updateDataURL(canvas);
};

const setTextboxFromEvent = (canvas, textbox, { target }) => {
  setTextboxValue(canvas, textbox, target.value);
};

const makeLinkedTextbox = (canvas, selector, opts) => {
  const box = new fabric.Textbox("", {
    ...textboxDefaults,
    ...opts,
  });
  box.on("input", updateDataURL.bind(box, canvas));

  var input = document.querySelector(selector);

  canvas.add(box);

  setTextboxValue(canvas, box, input.value);
  input.addEventListener("input", setTextboxFromEvent.bind(input, canvas, box));

  return box;
};

const makeStaticTextbox = (canvas, value, opts) => {
  const box = new fabric.Textbox(value, {
    ...textboxDefaults,
    ...opts,
  });
  box.on("input", updateDataURL.bind(box, canvas));

  canvas.add(box);

  return box;
};

const prepareCanvas = (input, canvasElement) => {
  const inputContainer = input.parentElement;

  input.setAttribute("type", "hidden");

  canvasElement.setAttribute(
    "class",
    "social-media-preview-image rounded-lg border-2 border-gray-300"
  );
  canvasElement.setAttribute("width", 800);
  canvasElement.setAttribute("height", 418);
  inputContainer.appendChild(canvasElement);

  const canvas = new fabric.Canvas(canvasElement);
  canvas.dataURLInput = input;

  return canvas;
};

ready(() => {
  const input = document.querySelector(
    "[name='post[social_media_preview_image]']"
  );
  const canvasElement = document.createElement("canvas");
  const canvas = prepareCanvas(input, canvasElement);

  fabric.Image.fromURL(
    "/images/social-media-preview-background.png",
    function (oImg) {
      oImg.selectable = false;
      canvas.add(oImg);

      const title = makeLinkedTextbox(canvas, "[name='post[title]']", {
        left: 80,
        top: 80,
        width: 640,
        fontWeight: "bold",
        fontSize: 36,
      });

      makeLinkedTextbox(canvas, "[name='post[excerpt]']", {
        left: 80,
        width: 560,
        top: title.aCoords.bl.y + 20,
        fill: "#4B5563",
        fontSize: 18,
      });

      var name = document
        .querySelector("[property='og:site_name']")
        .getAttribute("content");
      makeStaticTextbox(canvas, name, {
        left: 80,
        width: 560,
        top: 48,
        fill: "#F87171",
        fontSize: 18,
        fontWeight: "bold",
      });

      var rect = new fabric.Rect({
        left: 0,
        top: 0,
        fill: "#F87171",
        width: 14,
        height: 418,
        selectable: false,
      });
      canvas.add(rect);

      updateDataURL(canvas);
    }
  );
});

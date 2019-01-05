export type GetDocumentOptions = {
  type?: string;
  multiple?: boolean;
};

export type DocumentResult = {
  type: 'success' | 'cancel';
  name?: string;
  size?: number;
  uri?: string;
  lastModified?: number;
  file?: File;
  output?: FileList | null;
};
